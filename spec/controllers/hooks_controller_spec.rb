require 'rails_helper'

RSpec.describe HooksController, :type => :controller do
  let(:user) { FactoryGirl.create(:user, github_token: ENV["GITHUB_TEST_TOKEN"]) }
  let!(:project) { FactoryGirl.create(:project, user: user, team: user.team) }
  let!(:repository) { FactoryGirl.create(:customer_know, project: project) }

  let(:hook_params) { { project_id: project.id, repository_id: repository.id } }

  describe "merged" do
    let(:params) { JSON.parse(File.read("spec/fixtures/github_hooks/merged.json")) }

    it "creates a converted pull request", vcr: { cassette_name: "hooks-controller_merged-featuree" } do
      expect {
        post :perform, params.merge(hook_params)
        expect(response).to be_success
      }.to change{ ConvertedPullRequest.count }.by(1)
    end

    it "creates a note", vcr: { cassette_name: "hooks-controller_merged-featuree" } do
      expect {
        post :perform, params.merge(hook_params)
      }.to change{ Note.count }.by(1)

      expect(Note.last.title).to eq("Something")
      expect(Note.last.markdown_body).to eq("Not Really")
    end

    it "does not publish the note", vcr: { cassette_name: "hooks-controller_merged-featuree" } do
      post :perform, params.merge(hook_params)
      expect(Note.last.published?).to eq(false)
    end

    context "with a converted PR" do
      before(:each) { post :perform, params.merge(hook_params) }
      let!(:converted_pr) { ConvertedPullRequest.last }

      it "doesn't create a note", vcr: { cassette_name: "hooks-controller_merged-already-converted" } do
        expect {
          post :perform, params.merge(hook_params)
        }.not_to change{ Note.count }
      end
    end
  end

  describe "closed, not merged" do
    let(:params) { JSON.parse(File.read("spec/fixtures/github_hooks/closed.json")) }

    it "doesn't create a converted pull request", vcr: { cassette_name: "hooks-controller_closed-not-merged" } do
      expect {
        post :perform, params.merge(hook_params)
      }.not_to change{ ConvertedPullRequest.count }
    end

    it "doesn't create a note", vcr: { cassette_name: "hooks-controller_closed-not-merged" } do
      expect {
        post :perform, params.merge(hook_params)
      }.not_to change{ Note.count }
    end
  end

  describe "re-open" do
    let(:params) { JSON.parse(File.read("spec/fixtures/github_hooks/reopened.json")) }

    it "doesn't create a converted pull request", vcr: { cassette_name: "hooks-controller_reopened" } do
      expect {
        post :perform, params.merge(hook_params)
      }.not_to change{ ConvertedPullRequest.count }
    end

    it "doesn't create a note", vcr: { cassette_name: "hooks-controller_reopened" } do
      expect {
        post :perform, params.merge(hook_params)
      }.not_to change{ Note.count }
    end
  end
end
