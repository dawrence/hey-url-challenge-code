# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::UrlsController, type: :controller do
  render_views

  let(:original_url) { 'http://example.com' }

  let(:body) { response.body }
  let(:json_body) { JSON.parse body }
  let(:data) { json_body['data'] }

  let(:params) do
    { original_url: original_url }
  end

  context 'with data' do
    let!(:urls) { FactoryBot.create_list(:url, 20) }

    describe 'GET #latest' do
      it 'shows the latest 10 URLs' do
        get :latest
        expect(data.length).to be <= 10
        expect(data.length).to be > 0
      end
    end

    describe 'POST #create' do
      let(:data) { json_body['data'] }

      it 'creates a new url' do
        post :create, params: params
        url = Url.last
        expect(data).not_to be_empty
        expect(response.status).to eq(200)
        expect(data['attributes']['original-url']).to eq(original_url)
        expect(data['attributes']['url']).not_to be_empty
        expect(data['attributes']['url']).to eq("/#{url.short_url}")
      end

      it 'does not create a new url' do
        expect{
          post :create, params: { original_url: '' }
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    describe 'GET #show' do
      let!(:url) { FactoryBot.create(:url) }
      let!(:click) { FactoryBot.create(:click, url_id: url.id) }

      let(:data) { json_body['data'] }
      let(:stats) { data['relationships']['clicks']['data'] }

      context 'with a given url' do
        before do
          get :show, params: { url: url.short_url }
        end

        it 'show data for the given url' do
          expect(response.status).to eq(200)
          expect(data['attributes']['original-url']).to eq(url.original_url)
          expect(data['attributes']['url']).not_to be_empty
          expect(data['attributes']['url']).to include(url.short_url)
        end

        it 'shows stats about the given URL' do
          expect(response.status).to eq(200)
          expect(stats.length).to be > 0
        end
      end

      it 'throws 404 when the URL is not found' do
        get :show, params: { url: 'whatever' }

        expect(response.status).to eq(404)
      end
    end
  end

  context 'without data' do
    describe 'GET #latest' do
      it 'shows the latest 10 URLs' do
        get :latest
        expect(response.status).to eq(200)
        expect(data).to be_empty
      end
    end
  end

  describe 'GET #stats' do
    let!(:url) { FactoryBot.create(:url) }
    let!(:click_chrome) do
      FactoryBot.create(
        :click,
        url_id: url.id,
        created_at: Time.zone.now,
        browser: 'Chrome',
        platform: 'OS X'
      )
    end

    let!(:click_firefox) do
      FactoryBot.create(
        :click,
        url_id: url.id,
        created_at: Time.zone.now,
        browser: 'Firefox',
        platform: 'Windows'
      )
    end

    let!(:click_safari) do
      FactoryBot.create(
        :click,
        url_id: url.id,
        created_at: Time.zone.now + 1.day,
        browser: 'Safari',
        platform: 'OS X'
      )
    end

    let(:stats) { url.stats }

    before do
      get :stats, params: { url: url.short_url }
    end

    it 'return number of clicks per day' do
      expect(json_body['clicks_per_day']).to eq (2)
    end

    it 'redirects to the original url' do
      expect(json_body['browsers']).to eq ('Chrome, Firefox, Safari')
    end

    it 'throws 404 when the URL is not found' do
      expect(json_body['platforms']).to eq ('OS X, Windows')
    end
  end
end
