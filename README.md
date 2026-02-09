# 🚀 Sistema de Avaliação - MVP Saúde do Homem

Bem-vindo ao repositório do **Sistema de Avaliação MVP**. Este aplicativo Flutter foi desenvolvido para facilitar o processo de avaliação de projetos acadêmicos/hackathons, permitindo que professores atribuam notas, validem critérios e acompanhem resultados em tempo real.

---

## ✨ Pontos Fortes e Destaques

### 1. **Sincronização em Tempo Real (Real-time)**
O aplicativo utiliza o poder do **Cloud Firestore** com `StreamBuilders`. Isso significa que:
- Assim que um professor envia uma nota, a tela de resultados é atualizada instantaneamente para todos os usuários conectados.
- Não há necessidade de "puxar para atualizar" (pull-to-refresh).

### 2. **Cálculo Automático e Complexo de Notas**
O sistema abstrai a complexidade matemática da avaliação:
- **Conversão de Escalas:** As notas são inseridas na escala 0-10 (padrão brasileiro) e automaticamente convertidas e ponderadas para a escala final do evento (0-5).
- **Média Dinâmica:** O sistema calcula a média baseada no número de avaliadores que já submeteram notas.

### 3. **Gestão de Penalidades Individuais**
Diferente de sistemas simples que dão nota apenas ao grupo, este projeto permite a **penalização individual**:
- Professores podem marcar alunos específicos com "nota zero" dentro de um grupo.
- O sistema visualiza claramente quem foi penalizado e por qual avaliador.

### 4. **Busca Inteligente**
A tela de resultados possui um algoritmo de filtragem híbrido que permite buscar tanto pelo **nome do projeto** quanto pelo **nome de qualquer integrante** do grupo.

### 5. **UX/UI Polida e Validada**
- **Feedback Visual:** Cores indicam status (Verde: Avaliado/Aprovado, Laranja: Pendente, Vermelho: Reprovado/Zerado).
- **Validação Robusta:** O formulário de avaliação impede envio de notas fora do intervalo permitido ou campos vazios, com mensagens de erro claras.

---

## 🏗 Decisões Arquiteturais

O projeto segue uma arquitetura pragmática e escalável, focada na separação de responsabilidades:

### **Camada de Modelo (Models)**
Localizada em `lib/models/`. Classes puras (`TeamModel`, `StudentModel`, `ProfessorModel`) responsáveis por:
- Mapear dados do Firestore.
- Serialização/Deserialização (ToMap/FromMap).
- Conter regras de negócio leves (ex: verificação de presença).

### **Camada de Visualização (Screens)**
Localizada em `lib/screens/`. Responsável pela interface do usuário e interação:
- **DashboardScreen:** Listagem reativa dos times.
- **EvaluationFormScreen:** Lógica de formulário e validação de input.
- **GradesResultScreen:** Agregação de dados e exibição analítica.

### **Backend-as-a-Service (Firebase)**
A escolha do Firebase elimina a necessidade de um backend dedicado para este MVP, garantindo:
- Autenticação simplificada.
- Banco de dados NoSQL flexível para estruturas de times dinâmicas.
- Escalabilidade imediata.

---

## 📂 Estrutura de Diretórios

```
lib/
├── firebase_options.dart  # Configurações geradas do Firebase
├── main.dart             # Ponto de entrada e configuração do tema
├── models/               # Classes de domínio e dados
│   ├── professor_model.dart
│   ├── student_model.dart
│   └── team_model.dart
└── screens/              # Telas da aplicação
    ├── dashboard_screen.dart
    ├── evaluation_form_screen.dart
    ├── grades_result_screen.dart
    └── login_screen.dart
```

---

## 🚀 Como Executar o Projeto

### Pré-requisitos
- [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado.
- Conta no Google/Firebase.

### Passo 1: Clonar o Repositório
```bash
git clone https://github.com/yagoliveira92/avaliacao_mvp.git
cd avaliacao_mvp
```

### Passo 2: Instalar Dependências
```bash
flutter pub get
```

### Passo 3: Configurar o Firebase (Crítico)
Como este projeto utiliza Firebase, você precisa configurar suas próprias credenciais, pois os arquivos de segurança (`google-services.json` e `GoogleService-Info.plist`) não são versionados por segurança.

1. Crie um projeto no [Console do Firebase](https://console.firebase.google.com/).
2. Adicione um app **Android** (pacote: `br.dev.yago.avaliacao_mvp`).
   - Baixe o `google-services.json` e coloque em: `android/app/google-services.json`.
3. Adicione um app **iOS** (Bundle ID: `com.example.avaliacaoMvp`).
   - Baixe o `GoogleService-Info.plist` e coloque em: `ios/Runner/GoogleService-Info.plist`.
4. (Opcional) Ative o **Firestore Database** e **Authentication** no console.

### Passo 4: Executar
Certifique-se de ter um emulador rodando ou dispositivo conectado.

**Android/iOS:**
```bash
flutter run
```

---

## 📱 Telas Principais

| Tela | Descrição |
|------|-----------|
| **Login** | Acesso restrito aos professores avaliadores. |
| **Painel (Dashboard)** | Visão geral dos grupos. Ícones indicam se você já avaliou o grupo ou não. |
| **Avaliação** | Formulário com sliders ou campos numéricos para atribuir notas aos critérios. |
| **Resultados** | Tabela de classificação com notas finais calculadas (0-5.0) e status de aprovação. |

---

## 🤝 Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou pull requests.

1. Faça um Fork do projeto
2. Crie sua Feature Branch (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Adiciona: MinhaFeature'`)
4. Push para a Branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request