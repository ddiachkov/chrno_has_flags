# Описание
__chrno_has_flags__ -- реализация флагов на основе битовой маски для Rails.

Позволяет сохранять до 32 флагов в одном поле БД типа Integer (на машине с 32 битной архитектурой).

## Пример использования:

    class AddFlagsToUsers < ActiveRecord::Migration
      def change
        add_column :users, :flags, :integer, default: 0
      end
    end
    ...
    rake db:migrate
    ...
    class User < ActiveRecord::Base
      has_flags [ :is_admin, :is_editor ], field_name: "flags", default: [ :is_admin ]
    end
    ...
    user = User.new
    user.flags.is_admin?         #=> true
    user.flags.is_editor = true
    user.flags.to_s              #=> "is_admin, is_editor"
    user.flags.toggle! :is_admin
    user.flags                   #=> [ :is_editor ]
    user.available_flags         #=> [ :is_admin, :is_editor ]

Форма:

    ...
    <%= f.fields_for :flags do |m| %>
      <% f.object.available_flags.each do |flag| %>
        <%= m.check_box flag %><%= m.label flag %><br />
      <% end %>
    <% end %>
    ...