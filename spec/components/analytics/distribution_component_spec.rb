# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Analytics::DistributionComponent, type: :component do
  before { stub_current_space(build_stubbed(:space, currency: 'XOF')) }

  let(:rows) { [ [ 'Provisions', 2000 ], [ 'Transport', 1500 ], [ 'Eau', 300 ], [ 'Pain', 200 ] ] }

  it 'draws one segment per part and names the biggest ones' do
    page = render_inline(described_class.new(rows: rows))

    expect(page.css('.analyses-stack__seg').size).to eq(4)
    expect(page.css('.analyses-stack__seg').first['style']).to include('width: 50.0%')
    expect(page.css('.analyses-slim__name').map(&:text)).to eq([ 'Provisions', 'Transport', 'Eau',
                                                                 I18n.t('analytics.index.accounts_more', count: 1) ])
  end

  it 'folds the rest under a custom label' do
    page = render_inline(described_class.new(rows: rows, limit: 2, more_label: '2 other categories'))

    expect(page.css('.analyses-slim--muted .analyses-slim__name').text).to eq('2 other categories')
  end

  it 'renders nothing without rows' do
    expect(render_inline(described_class.new(rows: [])).to_html).to be_blank
  end
end
