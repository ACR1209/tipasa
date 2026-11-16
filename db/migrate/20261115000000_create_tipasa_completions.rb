class CreateTipasaCompletions < ActiveRecord::Migration[7.1]
  def change
    create_table :tipasa_completions do |t|
      t.references :owner, polymorphic: true, null: false, index: false
      t.string :tour_slug, null: false
      t.timestamps
    end
    add_index :tipasa_completions, %i[owner_type owner_id tour_slug], unique: true, name: "index_tipasa_completions_uniqueness"
  end
end
