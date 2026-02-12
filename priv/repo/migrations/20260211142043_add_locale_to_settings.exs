defmodule Craftplan.Repo.Migrations.AddLocaleToSettings do
  @moduledoc """
  Add locale column to the settings table.
  """

  use Ecto.Migration

  def up do
    alter table(:settings) do
      add :locale, :text, null: false, default: "en"
    end
  end

  def down do
    alter table(:settings) do
      remove :locale
    end
  end
end
