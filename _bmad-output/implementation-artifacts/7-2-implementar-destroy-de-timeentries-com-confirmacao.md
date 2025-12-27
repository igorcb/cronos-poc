# Story 7.2: Implementar Destroy de TimeEntries com Confirmação

Status: ready-for-dev

## Story

**Como** Igor,
**Quero** deletar entradas incorretas,
**Para que** dados sejam precisos.

## Acceptance Criteria

1. Link "Deletar" possui confirmação: "Tem certeza?" via Turbo
2. Rota `DELETE /time_entries/:id` deleta entrada permanentemente
3. Flash message: "Entrada deletada com sucesso"
4. Totalizadores recalculam via Turbo Stream
5. Entrada removida da lista sem reload de página
6. Se houver erro, mensagem clara é exibida

## Dev Notes

```ruby
def destroy
  @time_entry = TimeEntry.find(params[:id])
  @time_entry.destroy

  respond_to do |format|
    format.html { redirect_to time_entries_path, notice: "Entrada deletada com sucesso" }
    format.turbo_stream
  end
end
```
