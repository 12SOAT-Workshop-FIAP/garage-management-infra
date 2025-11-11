# Infraestrutura como Código (IaC) - Projeto Garage Management System

Este diretório contém todo o código de Infraestrutura como Código (IaC) para o projeto, utilizando [Terraform](https://www.terraform.io/) para provisionar e gerenciar os recursos na nuvem da AWS.

O objetivo é criar um ambiente robusto, seguro e escalável para hospedar a aplicação, utilizando um cluster Kubernetes gerenciado (EKS) e um banco de dados relacional externo (RDS).

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
  - **2 Subnets Privadas:** Para recursos que devem permanecer isolados e seguros, como os nós do Kubernetes e o banco de dados.
- **Internet Gateway:** Permite a comunicação de saída para a internet a partir das subnets públicas.
- **NAT Gateway:** Permite que os recursos nas subnets privadas (nós do EKS) iniciem conexões com a internet (ex: para baixar imagens Docker) sem serem expostos publicamente.
- **Route Tables:** Gerenciam o tráfego, direcionando o fluxo das subnets de acordo.

### 3. Segurança (Módulo `security`)

Controla o tráfego entre os recursos, atuando como um firewall virtual.
- **Security Group para EKS (`eks-nodes-sg`):** Um grupo para os nós de trabalho do Kubernetes, permitindo que eles se comuniquem e acessem a internet.
- **Security Group para RDS (`rds-sg`):** Um grupo para o banco de dados, altamente restritivo. A regra principal permite acesso **apenas** na porta `5432` (PostgreSQL) e **somente** se a origem for o Security Group dos nós do EKS.

### 4. Cluster Kubernetes (Módulo `eks`)

O ambiente de orquestração de contêineres onde nossa aplicação será executada.
- **EKS Control Plane:** A camada de gerenciamento do Kubernetes, provisionada e mantida pela AWS.
- **EKS Node Group:** Um grupo de instâncias EC2 (`t3.medium`) que atuam como os "worker nodes". Eles são provisionados nas subnets privadas para máxima segurança.

### 5. Banco de Dados (Módulo `rds`)

Um serviço de banco de dados PostgreSQL gerenciado, seguro e escalável.
- **Instância RDS:** Uma instância `db.t3.micro` executando PostgreSQL.
- **Posicionamento Seguro:** A instância é criada dentro das subnets privadas, garantindo que ela não seja acessível diretamente pela internet.

### 6. Container Registry (Módulo `ecr`)

- **Amazon ECR:** Um repositório privado (`garagemanagement`) para armazenar as imagens Docker da aplicação, com escaneamento de vulnerabilidades ativado.

## 🚀 Instruções para Provisionamento

### Pré-requisitos

1.  **Terraform CLI:** [Instalado](https://learn.hashicorp.com/tutorials/terraform/install-cli) na sua máquina.
2.  **AWS CLI:** [Instalado](https://aws.amazon.com/cli/) e [configurado](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) com as credenciais do ambiente AWS.

### Passos para Execução

1.  **Provisionar o Backend:**
    Primeiro, crie os recursos para o estado remoto.
    ```bash
    cd infra/backend
    terraform init
    terraform apply
    ```

2.  **Navegue até o diretório principal:**
    ```bash
    cd infra
    ```

3.  **Crie o arquivo de variáveis:**
    Crie um arquivo chamado `terraform.tfvars` e adicione as credenciais do banco de dados.
    ```hcl
    # infra/terraform.tfvars
    db_username = "seu_usuario_aqui"
    db_password = "sua_senha_segura_aqui"
    ```
    _Este arquivo já está no `.gitignore` para evitar o commit de segredos._

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