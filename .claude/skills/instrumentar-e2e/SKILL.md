---
name: instrumentar-e2e
description: Prepara o driva_editor para o teste E2E manual do dev, sem depender do backend pronto. Usada pelo QA após o gate do CISO. A instrumentação é temporária e nunca vai para produção.
---

# Skill: instrumentar o E2E

Objetivo: deixar o terreno pronto para o **dev humano** testar o fluxo inteiro de ponta a ponta. Esta fase não gera PR — tudo aqui é temporário.

Passos:
1. **Fakes e fixtures.** Se o backend não está pronto/estável, registre os repositórios fake no DI do flavor dev (`PagesRepositoryFake`, `EditorRepositoryFake`), com dados realistas — consulte o especialista de dados para o formato exato do payload e o de infra para o toggle de troca. Um fake honra o contrato de verdade (erros, casos de borda), não só a interface.
2. **Logs.** Plante `log()` (dart:developer) nos pontos que contam a história: carregar página, mutação da árvore, salvar, falhas. Prefixo `[e2e]` para a limpeza achar tudo depois.
3. **Atalhos.** Se o roteiro precisa de um estado difícil de alcançar, crie o atalho (página pré-populada, botão escondido em dev) — sempre atrás de flag de dev.
4. **Roteiro.** Escreva `docs/feature-<nome>/test_plan.md`: pré-condições (comandos para subir tudo), passos numerados (o que clicar/digitar), o que **observar** em cada passo, onde tirar **print** e salvar em `docs/feature-<nome>/evidencias/`. Roteiro de checklist de voo — nada de "teste a feature".
5. Cubra o caminho feliz, as exceções do PRD e os casos de borda (página vazia, spec inválido, backend fora).

Quando o E2E falhar: quem lê logs e prints e conserta é o **tech-lead** — você atualiza o roteiro se o fluxo mudou.

Regra de ouro: mantenha a lista de TUDO que foi instrumentado (arquivos e trechos) dentro do test_plan.md — é o mapa da limpeza no wrap.
