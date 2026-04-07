require "rails_helper"

RSpec.describe "Tasks filter Turbo Frame - Story 6.4", type: :request do
  let(:user) { create(:user, password: "Password123!") }
  let!(:company) { create(:company) }
  let!(:project) { create(:project, company: company) }

  before do
    post session_path, params: { email: user.email, password: "Password123!" }
  end

  describe "GET /tasks" do
    before { get tasks_path }

    describe "AC1 - turbo-frame wrapping da lista" do
      it "renders turbo-frame#time_entries_list" do
        expect(response.body).to include('<turbo-frame id="time_entries_list"')
      end

      it "contains the task list table inside turbo-frame" do
        frame_start = response.body.index('<turbo-frame id="time_entries_list"')
        frame_end   = response.body.index('</turbo-frame>', frame_start)
        frame_content = response.body[frame_start..frame_end]
        expect(frame_content).to include('bg-gray-800 shadow-sm rounded-lg')
      end

      it "filter form is present on page" do
        expect(response.body).to match(/data-controller="[^"]*filter[^"]*"/)
      end
    end

    describe "AC2 - formulário com data-controller=filter e data-turbo-action" do
      it "form has data-controller with filter value" do
        expect(response.body).to match(/data-controller="[^"]*filter[^"]*"/)
      end

      it "form has data-turbo-action=advance" do
        expect(response.body).to match(/data-controller="[^"]*filter[^"]*"[^>]*data-turbo-action="advance"|data-turbo-action="advance"[^>]*data-controller="[^"]*filter[^"]*"/)
      end
    end

    describe "AC2 - campos com change->filter#submit action" do
      it "page contains change->filter#submit action descriptor" do
        # Rails HTML-encodes '>' as '&gt;' in attributes
        expect(response.body).to include('change-&gt;filter#submit')
      end

      it "status select is present" do
        expect(response.body).to include('name="status"')
      end

      it "period select is present" do
        expect(response.body).to include('name="period"')
      end

      it "start_date input is present" do
        expect(response.body).to include('name="start_date"')
      end

      it "end_date input is present" do
        expect(response.body).to include('name="end_date"')
      end
    end

    describe "AC4 - URL update via data-turbo-action" do
      it "turbo-frame has data-turbo-action=advance" do
        expect(response.body).to include('data-turbo-action="advance"')
      end

      it "filter form has data-turbo-action=advance for URL history push" do
        expect(response.body).to include('data-turbo-action="advance"')
        expect(response.body).to match(/data-controller="[^"]*filter[^"]*"/)
      end
    end

    describe "AC3 - header/sidebar fora do turbo-frame" do
      it "Nova Tarefa link is before turbo-frame in DOM" do
        frame_start = response.body.index('<turbo-frame id="time_entries_list"')
        link_pos    = response.body.index('Nova Tarefa')
        expect(link_pos).to be < frame_start
      end

      it "filter form is before turbo-frame in DOM" do
        frame_start  = response.body.index('<turbo-frame id="time_entries_list"')
        form_pos     = response.body.index('data-controller="filter"')
        expect(form_pos).to be < frame_start
      end
    end
  end
end
