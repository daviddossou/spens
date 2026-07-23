class AddSpaceToLearnedVocabulary < ActiveRecord::Migration[8.0]
  def change
    %i[learned_aliases learned_keywords].each do |table|
      add_reference table, :space, type: :uuid, null: true, foreign_key: true, index: true
      # Raw phrase as typed/imported, for display and picker search terms (phrase is normalized).
      add_column table, :display_phrase, :string

      remove_index table, :phrase, unique: true
      add_index table, :phrase, unique: true, where: "space_id IS NULL",
                name: "index_#{table}_on_phrase_global"
      add_index table, [ :phrase, :space_id ], unique: true, where: "space_id IS NOT NULL",
                name: "index_#{table}_on_phrase_and_space"
    end
  end
end
