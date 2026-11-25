# frozen_string_literal: true

module StatementImports
  # Creates an import from the uploaded captures and queues the reading. Returns the import;
  # check `persisted?` and its errors.
  class Start
    def self.call(space:, user:, captures:, account: nil)
      import = space.statement_imports.new(user: user, account: account, captures: captures)
      unless user.can_use_statement_import? && Reader.enabled?
        import.errors.add(:base, :unavailable)
        return import
      end
      ReadJob.perform_later(import.id) if import.save
      import
    end
  end
end
