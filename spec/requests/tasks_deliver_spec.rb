require "rails_helper"

RSpec.describe "Tasks#deliver", type: :request do
  let(:user) { User.create!(email: "deliver@example.com", password: "password123") }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password123" }
  end

  let(:company) { create(:company) }
  let(:project) { create(:project, company: company) }

  describe "PATCH /tasks/:id/deliver" do
    context "sem autenticação" do
      let(:task) { create(:task, :completed, company: company, project: project) }

      it "redireciona para login" do
        patch deliver_task_path(task), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "com autenticação" do
      before { sign_in(user) }

      context "quando a task está completed" do
        let!(:task) { create(:task, :completed, company: company, project: project) }

        it "retorna turbo_stream removendo a linha" do
          patch deliver_task_path(task),
                headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response).to have_http_status(:ok)
          expect(response.content_type).to include("text/vnd.turbo-stream.html")
          expect(response.body).to include("task_row_#{task.id}")
          expect(response.body).to include("remove")
        end

        it "atualiza o status para delivered" do
          patch deliver_task_path(task),
                headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(task.reload.status).to eq("delivered")
        end

        it "preenche a delivery_date automaticamente" do
          patch deliver_task_path(task),
                headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(task.reload.delivery_date).to eq(Date.current)
        end
      end

      context "quando a task está pending" do
        let!(:task) { create(:task, :pending, company: company, project: project) }

        it "não altera o status" do
          expect {
            patch deliver_task_path(task),
                  headers: { "Accept" => "text/vnd.turbo-stream.html" }
          }.not_to change { task.reload.status }
        end

        it "retorna unprocessable_entity" do
          patch deliver_task_path(task),
                headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "quando a task já está delivered" do
        let!(:task) { create(:task, :delivered, company: company, project: project, delivery_date: Date.current) }

        it "não altera o status" do
          expect {
            patch deliver_task_path(task),
                  headers: { "Accept" => "text/vnd.turbo-stream.html" }
          }.not_to change { task.reload.status }
        end

        it "retorna unprocessable_entity" do
          patch deliver_task_path(task),
                headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end
end
