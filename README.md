# Avaliação MVP - Sistema de Avaliação de Projetos

Este projeto é um aplicativo móvel e web desenvolvido em Flutter, projetado para permitir que professores avaliem projetos de equipes de alunos de forma eficiente e centralizada. O sistema utiliza o Firebase como backend para armazenamento de dados e autenticação.

## Destaques do Projeto

- **Multiplataforma:** Construído com Flutter, o aplicativo pode ser compilado para Android, iOS e Web a partir de uma única base de código.
- **Backend Robusto com Firebase:** Utiliza os serviços do Firebase para uma infraestrutura de backend escalável e sem servidor.
    - **Cloud Firestore:** Banco de dados NoSQL em tempo real para armazenar dados sobre professores, equipes e avaliações.
    - **Autenticação Segura:** O login é controlado através de uma lista de permissões (`allowlist`) no Firestore, garantindo que apenas professores autorizados possam acessar o sistema.
- **Arquitetura Limpa:** O código é organizado com uma clara separação de responsabilidades:
    - **Models:** Estruturas de dados bem definidas (`ProfessorModel`, `TeamModel`, `StudentModel`) que incluem a lógica de serialização/desserialização para o Firebase.
    - **Screens (Telas):** A interface do usuário é dividida em componentes modulares, cada um responsável por uma funcionalidade específica (Login, Painel Principal, Formulário de Avaliação).
- **Interface Reativa:** A tela principal (`DashboardScreen`) utiliza um `StreamBuilder` para se conectar ao Firestore, atualizando a lista de equipes em tempo real sempre que há uma alteração nos dados.
- **Interface Intuitiva:** O design segue as diretrizes do Material Design, proporcionando uma experiência de usuário familiar e fácil de usar.

## Estrutura do Projeto

O projeto está organizado da seguinte forma:

```
lib/
├── models/             # Define os modelos de dados da aplicação (Professor, Aluno, Equipe).
├── screens/            # Contém as telas da interface do usuário.
│   ├── login_screen.dart       # Tela de login para professores.
│   ├── dashboard_screen.dart   # Painel principal com a lista de equipes.
│   ├── evaluation_form_screen.dart # Formulário para registrar a avaliação de uma equipe.
│   └── grades_result_screen.dart # Tela para visualizar os resultados consolidados.
├── firebase_options.dart # Configurações do Firebase para as diferentes plataformas.
└── main.dart           # Ponto de entrada da aplicação.
```

## Passo a Passo para Execução

Siga as instruções abaixo para configurar e executar o projeto em seu ambiente de desenvolvimento.

### 1. Pré-requisitos

- **Flutter:** Certifique-se de ter o [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado.
- **Firebase Account:** Você precisará de uma conta do Google para criar e gerenciar o projeto no Firebase.
- **Firebase CLI:** Instale a CLI do Firebase (`npm install -g firebase-tools`).

### 2. Configuração do Firebase

1.  **Crie um Projeto no Firebase:**
    - Acesse o [console do Firebase](https://console.firebase.google.com/).
    - Clique em "Adicionar projeto" e siga as instruções.

2.  **Configure o Cloud Firestore:**
    - No menu do seu projeto no Firebase, vá para **Build > Firestore Database**.
    - Clique em "Criar banco de dados" e inicie no **modo de produção**.

3.  **Crie as Coleções Necessárias:**
    - **`professors_allowlist`**:
        - Crie esta coleção para gerenciar o acesso dos professores.
        - Para cada professor, crie um documento onde o **ID do Documento** é a **matrícula** do professor.
        - Dentro do documento, adicione um campo `nome` (String) com o nome do professor.
        - Exemplo: Documento com ID `123456` teria o campo `nome: "Prof. Silva"`.
    - **`teams`**:
        - Crie esta coleção para armazenar as equipes a serem avaliadas. A estrutura dos documentos deve seguir o `TeamModel` (ver em `lib/models/team_model.dart`).

4.  **Configure seu App no Firebase:**
    - No console do Firebase, adicione os aplicativos para as plataformas desejadas (Android, iOS, Web).
    - Use o **FlutterFire CLI** para conectar seu aplicativo local ao projeto Firebase. Execute o seguinte comando na raiz do projeto e siga as instruções:
      ```sh
      flutterfire configure
      ```
    - Isso irá gerar automaticamente o arquivo `lib/firebase_options.dart` com as configurações corretas.

### 3. Executando o Projeto Localmente

1.  **Clone o Repositório:**
    ```sh
    git clone <URL_DO_REPOSITORIO>
    cd avaliacao_mvp
    ```

2.  **Instale as Dependências:**
    ```sh
    flutter pub get
    ```

3.  **Execute o Aplicativo:**
    - Selecione um dispositivo (emulador, simulador ou dispositivo físico) ou a plataforma web.
    - Execute o comando:
      ```sh
      flutter run
      ```

4.  **Login:**
    - Na tela de login, insira a matrícula de um professor que você adicionou à coleção `professors_allowlist` no Firestore.

Agora o aplicativo deve estar funcionando e conectado ao seu projeto Firebase.