# AGENTS.md — Sentinela

Guia de convenções para agentes/IA trabalhando neste repositório Flutter.

## Stack
- Flutter (Dart >= 3.9) + Firebase (Auth, Cloud Firestore).
- Alvo de publicação: Google Play + Apple Store. Nunca usar `com.example.*` em produção.

## Comandos de verificação (sempre executar antes de terminar uma tarefa)
- `flutter analyze`            → deve terminar sem erros
- `flutter test`               → todos os testes verdes
- `flutter build apk --debug` e `flutter build ios --no-codesign` para validar build

## Princípios obrigatórios (TDD / SOLID / Clean Code)
1. **Testes primeiro.** Toda lógica de negócio (controllers/serviços/repos) deve ter teste
   unitário. Regras de negócio nunca ficam dentro de widgets.
2. **Dependência injetada (DIP).** NUNCA chamar `FirebaseAuth.instance` ou
   `FirebaseFirestore.instance` dentro de controllers, serviços ou widgets.
   Dependa de interfaces de repositório/datasource e injete por construtor.
3. **Single Responsibility.** Um arquivo = uma responsabilidade.
   Widgets só orquestram UI; dados ficam em repos/datasources; regras de domínio ficam
   em controllers/services.
4. **Tipagem forte.** Evite `Future<List>`, `Map`/`dynamic`, `.get('campo')` e strings
   mágicas. Use models tipados (`Profile`, `Unit`, `Registry`, `Permission`) e constantes.
5. **DRY.** Não duplique queries ou formatos. Reutilize repositórios e helpers.
6. **Sem código morto.** Remova imports/widgets/dependências não utilizados. Não deixe
   blocos comentados no código.

## Estrutura de diretórios (seguir)
```
lib/
  core/            # Result/Either, erros, constantes globais
  data/
    datasources/   # FirestoreDatasource, AuthDatasource (implementações)
    repositories/  # interfaces de repositório (Auth, Unit, Profile, Registry, Report)
    models/        # models tipados com fromMap/toMap (sem import de cloud_firestore)
  domain/          # controllers/serviços de negócio puros e testáveis
  pages/           # widgets de tela
  widgets/         # componentes de UI reutilizáveis
  main.dart
  firebase_options.dart
test/
  data/  domain/  widgets/
```

## Regras de dados Firestore (contrato atual)
- Coleção `units` (name, owner_id) → subcoleção `registries` (created_at, type,
  license_plate, driver, document_number, unit_id, notes, author_id)
- Subcoleção `permissions` (user_id, unit_id, unit_name, role: owner|guest, expires_at?).
  Doc id = `user_id` (determinístico; é o que as Security Rules usam para `isMember`).
  Autorização de dono deriva de `units.owner_id` (não da permissão), evitando escalonamento.
- Security Rules em `firestore.rules` são a autoridade; checagens no client (datasources)
  são defesa em profundidade.
- Coleção `profiles` (docId = uid; name, email, registry)
- `collectionGroup('permissions')` para consultas por usuário.
- Consistência: `isUnitGuest`/`isUnitOwner` usam `permissions` (nunca `unit_guests`).

## Convenções
- Português (pt-BR) nos textos de UI.
- Sem comentários desnecessários no código.
- Versionamento do app em `pubspec.yaml` (bump para cada release).
