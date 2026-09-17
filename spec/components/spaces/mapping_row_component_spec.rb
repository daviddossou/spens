# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spaces::MappingRowComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  describe "a category alias" do
    let(:mapping) { LearnedAlias.personal_teach(space: space, phrase: "zem", taxonomy_key: "public_transport") }
    let(:rendered) { render_inline(described_class.new(space: space, mapping: mapping)) }

    it "quotes the phrase" do
      expect(rendered.at_css(".mapping-card .member-card__name").text).to eq("« zem »")
    end

    it "retargets the category through a PATCH form that submits on change" do
      form = rendered.at_css("form.mapping-card__retarget")
      expect(form["action"]).to eq("/spaces/#{space.id}/mappings/#{mapping.id}")
      expect(form.at_css("input[name='_method']")["value"]).to eq("patch")
      select = form.at_css("select[name='taxonomy_key']")
      expect(select["data-controller"]).to eq("searchable-select")
      expect(select["onchange"]).to eq("this.form.requestSubmit()")
      expect(select["aria-label"]).to eq("zem")
      expect(select.at_css("option[selected]")["value"]).to eq("public_transport")
      expect(select.css("optgroup").map { |g| g["label"] }).to include("Expense", "Income")
    end

    it "forgets the alias with a confirmed DELETE" do
      form = rendered.css("form").find { |f| f.at_css("input[name='_method'][value='delete']") }
      expect(form["action"]).to eq("/spaces/#{space.id}/mappings/#{mapping.id}")
      expect(form["data-turbo-confirm"]).to eq("Forget \"zem\"?")
      expect(form.at_css("button.link-button--danger").text).to eq("Forget")
    end
  end

  describe "a kind keyword" do
    let(:mapping) { LearnedKeyword.personal_teach(space: space, phrase: "depanne", kind: "debt_out") }
    let(:rendered) { render_inline(described_class.new(space: space, mapping: mapping, keyword: true)) }

    it "shows the phrase and the kind it maps to, without a select" do
      expect(rendered.at_css(".member-card__name").text).to eq("« depanne »")
      expect(rendered.at_css(".member-card__email").text).to eq("Debt (lent)")
      expect(rendered.at_css("select")).to be_nil
    end

    it "forgets the keyword through the keyword-typed DELETE" do
      form = rendered.at_css("form")
      expect(form["action"]).to eq("/spaces/#{space.id}/mappings/#{mapping.id}?type=keyword")
      expect(form.at_css("input[name='_method']")["value"]).to eq("delete")
      expect(form["data-turbo-confirm"]).to eq("Forget \"depanne\"?")
    end
  end
end
