# Registro de Execução de QA & Segurança - BoraGás
**Identificador da Rodada (testRunId):** `QA-RUN-20261111-01`  
**Data:** 11/11/2026  
**Responsável:** Engenheiro de QA Sênior & Segurança  

---

## 1. Evidências do Backup Pré-Teste
- **Diretório de Backup:** `C:\Users\User\.gemini\antigravity\scratch\boragas\backups\pre_qa_backup_20261111\`
- **Ambiente de Banco Conectado:** Supabase Oficial (`https://elkelrotleuyszmtkbye.supabase.co`)
- **Estado Inicial das Tabelas no Banco:**
  - `stores`: 2 registros existentes (Ultragaz Paulistana Express e Liquigás Central do Gás).
  - `products`: 3 registros existentes (Botijão P13 Ultragaz, Água 20L Bonafont, Botijão P13 Liquigás).
  - `orders`: 0 registros (Limpo, sem nenhum pedido real ou teste anterior).
  - `order_items`: 0 registros.
  - `profiles`: 0 registros.
  - `storage`: 0 buckets e 0 arquivos.
  - `mock_database.dart`: Backup idêntico salvo em `mock_database_backup.dart`.

---

## 2. Padrão de Identificação para Isolamento e Limpeza
Todos os artefatos e dados que forem criados durante a Etapa 2 de testes utilizarão os seguintes padrões:
- **Prefixo de Nomes:** `[QA-TESTE]`
- **E-mails de Teste:** `teste+<funcao>@qa-teste.local`
- **ID de Pedidos Teste:** Prefixados com `ord-qa-`
- **Telefones de Teste:** `(11) 90000-00XX`
- **Tabela de Log de Entidades Criadas no Teste:**
| Tipo de Entidade | ID / Chave | Nome / Identificador | Criado em | Status da Limpeza |
|---|---|---|---|---|
| Perfil (Cliente) | usr-qa-cust-1 | [QA-TESTE] Cliente Fulano | 11/11/2026 | ✅ LIMPO (Zero resíduos) |
| Perfil (Lojista) | usr-qa-merch-1 | [QA-TESTE] Distribuidora Central | 11/11/2026 | ✅ LIMPO (Zero resíduos) |
| Perfil (Entregador) | usr-qa-cour-1 | [QA-TESTE] Piloto Rápido | 11/11/2026 | ✅ LIMPO (Zero resíduos) |
| Distribuidora | store-qa-test-1 | [QA-TESTE] Central de Gás e Água | 11/11/2026 | ✅ LIMPO (Zero resíduos) |
| Produto (Gás) | prod-qa-gas-1 | [QA-TESTE] Botijão GLP 13kg | 11/11/2026 | ✅ LIMPO (Zero resíduos) |
| Produto (Água) | prod-qa-water-1 | [QA-TESTE] Galão de Água 20L | 11/11/2026 | ✅ LIMPO (Zero resíduos) |
| Pedido (Pix) | ord-qa-pix-1 | #BG-QA-01 (Pix Sandbox) | 11/11/2026 | ✅ LIMPO (Zero resíduos) |
| Pedido (Dinheiro) | ord-qa-cash-1 | #BG-QA-02 (Dinheiro + Troco) | 11/11/2026 | ✅ LIMPO (Zero resíduos) |
| Pedido (Workflow) | ord-qa-flow-1 | #BG-QA-03 (Ciclo PIN 4821) | 11/11/2026 | ✅ LIMPO (Zero resíduos) |

---

## 4. Auditoria de Limpeza Pós-Testes (Etapa 5)
- **Data da Limpeza:** 11/11/2026 12:30
- **Verificação de Marcadores `[QA-TESTE]`:** ZERO registros retornados.
- **Tabela Comparativa de Integridade (Antes vs Depois):**
  - `stores`: 2 no backup inicial -> 2 pós-limpeza (100% íntegro)
  - `products`: 3 no backup inicial -> 3 pós-limpeza (100% íntegro)
  - `orders`: 0 no backup inicial -> 0 pós-limpeza (100% íntegro)
  - `order_items`: 0 no backup inicial -> 0 pós-limpeza (100% íntegro)
  - `profiles`: 0 no backup inicial -> 0 pós-limpeza (100% íntegro)
  - `storage`: 0 buckets no backup inicial -> 0 buckets pós-limpeza (100% íntegro)
- **Conclusão:** O sistema retornou com precisão matemática exata ao estado original pré-teste.


---

## 3. Preservação Obrigatória
Os seguintes dados NÃO serão alterados nem apagados durante a limpeza final:
1. As 2 distribuidoras pré-existentes (`stores.json`).
2. Os 3 produtos padrão pré-existentes (`products.json`).
3. As configurações de rotas, taxas de comissão (8%), remote config e termos.
4. Qualquer conta administrativa prévia.
