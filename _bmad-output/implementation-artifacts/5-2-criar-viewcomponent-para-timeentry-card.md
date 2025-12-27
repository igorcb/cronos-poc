# Story 5.2: Criar ViewComponent para TimeEntry Card

Status: ready-for-dev

## Story

**Como** desenvolvedor,
**Quero** componente reutilizável para exibir TimeEntry,
**Para que** UI seja consistente e testável.

## Acceptance Criteria

1. Component recebe `entry:` como parâmetro
2. Template exibe todos os campos de forma organizada
3. Status tem badge colorido: pending=yellow, completed=green, reopened=orange, delivered=blue
4. Valor monetário é destacado em verde
5. Links de "Editar" e "Deletar" aparecem no card
6. Component é testável isoladamente
7. `bundle exec rspec spec/components/time_entry_card_component_spec.rb` passa 100%

## Dev Notes

```ruby
# app/components/time_entry_card_component.rb
class TimeEntryCardComponent < ViewComponent::Base
  attr_reader :entry

  def initialize(entry:)
    @entry = entry
  end

  def status_class
    {
      'pending' => 'bg-yellow-100 text-yellow-800',
      'completed' => 'bg-green-100 text-green-800',
      'reopened' => 'bg-orange-100 text-orange-800',
      'delivered' => 'bg-blue-100 text-blue-800'
    }[entry.status]
  end
end
```

```erb
<!-- app/components/time_entry_card_component.html.erb -->
<div class="p-4 border rounded-lg shadow">
  <div class="flex justify-between">
    <h3 class="font-semibold"><%= entry.company.name %></h3>
    <span class="px-2 py-1 rounded text-xs <%= status_class %>">
      <%= entry.status.titleize %>
    </span>
  </div>
  <p class="text-sm text-gray-600"><%= entry.project.name %></p>
  <p class="mt-2"><%= entry.formatted_duration %> - <%= l(entry.date) %></p>
  <p class="text-sm"><%= entry.activity %></p>
  <div class="mt-3 flex justify-between items-center">
    <span class="text-lg font-bold text-green-600">
      R$ <%= number_to_currency(entry.calculated_value, unit: '') %>
    </span>
    <div class="space-x-2">
      <%= link_to "Editar", edit_time_entry_path(entry), class: "text-blue-600 hover:underline text-sm" %>
      <%= button_to "Deletar", time_entry_path(entry), method: :delete,
          class: "text-red-600 hover:underline text-sm",
          data: { turbo_confirm: "Tem certeza?" } %>
    </div>
  </div>
</div>
```
