# Infraestrutura como Código (IaC) - Projeto Garage Management System

Este diretório contém todo o código de Infraestrutura como Código (IaC) para o projeto, utilizando [Terraform](https://www.terraform.io/) para provisionar e gerenciar os recursos na nuvem da AWS.

O objetivo é criar um ambiente robusto, seguro e escalável para hospedar a aplicação, utilizando um cluster Kubernetes gerenciado (EKS).

## 🏛️ Arquitetura e Recursos Criados

A infraestrutura é modularizada para garantir reusabilidade e clareza. Os seguintes recursos são provisionados:

### 1. Terraform Backend (Diretório `backend`)

Para garantir um ambiente de trabalho colaborativo e seguro, o estado do Terraform é gerenciado remotamente:

- **Amazon S3:** Um bucket S3 (`garagemanagement-terraform-backend`) é usado para armazenar o arquivo de estado (`terraform.tfstate`), com versionamento e criptografia ativados.
- **Amazon DynamoDB:** Uma tabela (`garagemanagement-terraform-locks`) é usada para o travamento do estado (state locking), prevenindo que múltiplos `applys` sejam executados simultaneamente.

### 2. Rede (Módulo `vpc`)

A base da nossa infraestrutura, focada em segurança e alta disponibilidade.

- **VPC:** Uma rede virtual privada (`10.0.0.0/16`) para isolar nossos recursos.
- **Subnets:** Quatro subnets distribuídas em duas Zonas de Disponibilidade (`us-east-1a` e `us-east-1b`) para garantir resiliência:
  - **2 Subnets Públicas:** Para recursos que precisam de acesso à internet, como o NAT Gateway.
  - **2 Subnets Privadas:** Para recursos que devem permanecer isolados e seguros, como os nós do Kubernetes.
- **Internet Gateway:** Permite a comunicação de saída para a internet a partir das subnets públicas.
- **NAT Gateway:** Permite que os recursos nas subnets privadas (nós do EKS) iniciem conexões com a internet (ex: para baixar imagens Docker) sem serem expostos publicamente.
- **Route Tables:** Gerenciam o tráfego, direcionando o fluxo das subnets de acordo.

### 3. Segurança (Módulo `security`)

Controla o tráfego entre os recursos, atuando como um firewall virtual.

- **Security Group para EKS (`eks-nodes-sg`):** Um grupo para os nós de trabalho do Kubernetes, permite tráfego de entrada _apenas_ do ALB interno na porta do NodePort.
- **Security Group para ALB (`alb-internal-sg`):** Permite tráfego de entrada na porta 80 (do API Gateway) e de saída para os EKS nodes.
- **Security Group para RDS (`rds-sg`):** Um grupo para o banco de dados, altamente restritivo. A regra principal permite acesso **apenas** na porta `5432` (PostgreSQL) e **somente** se a origem for das sub-redes privadas (private_subnet_cidrs).

### 4. Cluster Kubernetes (Módulo `eks`)

O ambiente de orquestração de contêineres onde nossa aplicação será executada.

- **EKS Control Plane:** A camada de gerenciamento do Kubernetes, provisionada e mantida pela AWS.
- **EKS Node Group:** Um grupo de instâncias EC2 (`t3.medium`) que atuam como os "worker nodes". Eles são provisionados nas subnets privadas para máxima segurança.

### 5. API Gateway e Roteamento (Módulo `api-gateway`)

Controla todo o tráfego de entrada, agindo como o portão principal da aplicação.

- **API Gateway (HTTP API):** Cria um endpoint público único para todos os serviços.
- **Application Load Balancer (ALB):** Um ALB _interno_ (privado) é criado para receber tráfego do API Gateway e distribuí-lo para o EKS.
- **VPC Link:** O componente que conecta o API Gateway (público) ao ALB (privado) de forma segura.
- **Roteamento:** As rotas `ANY /auth/{proxy+}` são enviadas para a Lambda de autenticação, enquanto a rota `$default` (todo o resto) é enviada para o EKS via ALB.

### 6. Container Registry (Módulo `ecr`)

- **Amazon ECR:** Um repositório privado (`garagemanagement`) para armazenar as imagens Docker da aplicação, com escaneamento de vulnerabilidades ativado.

## 🚀 Instruções para Provisionamento

### Pré-requisitos

1.  **Terraform CLI:** [Instalado](https://learn.hashicorp.com/tutorials/terraform/install-cli) na sua máquina.
2.  **AWS CLI:** [Instalado](https://aws.amazon.com/cli/) e [configurado](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) com as credenciais do ambiente AWS.

### Configuração Inicial (Backend Remoto)

Passo Obrigatório: Antes de rodar qualquer automação, é necessário criar os recursos que armazenarão o estado do Terraform (Bucket S3 e DynamoDB Lock).
```bash
cd backend
terraform init
terraform apply
```

### Deploy Automatizado (CI/CD via GitHub Actions)
Esta é a forma recomendada para ambientes de produção (branch main).

1.  **Configure os Secrets no GitHub:**
No seu repositório, vá em Settings > Secrets and variables > Actions e adicione:
    ```bash
    AWS_ACCESS_KEY_ID: Sua Access Key da AWS.
    AWS_SECRET_ACCESS_KEY: Sua Secret Key da AWS.
    AWS_SESSION_TOKEN: Necessário se estiver usando credenciais temporárias.
    LAMBDA_AUTH_ARN: O ARN da sua função Lambda de autenticação.
    ```

2.  **Dispare o Deploy:**
Faça qualquer alteração na pasta garage-management-infra e dê push na branch main.
O pipeline iniciará automaticamente:
    - Validação e Plan: Ocorrem automaticamente.
    - Apply: Ocorre automaticamente após o sucesso do plano.
Acompanhe a execução na aba Actions do GitHub.

### Execução Manual (Desenvolvimento Local)

1.  **Provisionar o Backend:**
    Primeiro, crie os recursos para o estado remoto.

    ```bash
    cd backend
    terraform init
    terraform apply
    ```

2.  **Navegue até o diretório principal:**

    ```bash
    cd ..
    ```

3.  **Crie o arquivo de variáveis:**
    Crie um arquivo chamado `terraform.tfvars`. A única variável obrigatória é o ARN da sua função Lambda de autenticação.

    ```hcl
    # infra/terraform.tfvars
    lambda_auth_arn = "arn:aws:lambda:us-east-1:ACCOUNT_ID:function:NOME_DA_SUA_LAMBDA"
    ```

    _(Opcional: Você também pode sobrescrever os valores padrão, como `project_name` ou `app_node_port` neste arquivo, se desejar)._

4.  **Inicialize o Terraform:**

    ```bash
    terraform init
    ```

5.  **Planeje e Aplique:**
    Revise os recursos a serem criados e confirme a aplicação. O processo pode levar até 20 minutos.
    ```bash
    terraform plan
    terraform apply
    ```

### Acesso Pós-Provisionamento

1.  **Configure o `kubectl`:**
    O `cluster_name` é `garagemanagement` por padrão.

    ```bash
    aws eks update-kubeconfig --region us-east-1 --name garagemanagement
    ```

2.  **Verifique a Conexão e os Outputs:**

    ```bash
    # Verifica se os nós estão prontos
    kubectl get nodes

    # Exibe os endpoints e nomes criados
    terraform output
    ```

    O output mais importante é o `api_gateway_endpoint`. Este é o novo endereço público único para acessar _toda_ a sua aplicação (tanto a autenticação quanto a API principal).

    ```bash
    terraform output api_gateway_endpoint
    ```
