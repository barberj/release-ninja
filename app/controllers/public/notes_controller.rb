class Public::NotesController < Public::BaseController
  def show
    @project = project
    @grouped_notes = NoteGrouper.new(notes).call
  end

  def rss
    @project ||= Project.eager_load(:notes).friendly.find(id)
  rescue ActiveRecord::RecordNotFound
    render text: 'Invalid Project', status: :not_found
  end

  private

  def id
    params[:id] || request.subdomains.first
  end

  def project
    @project ||= Project.friendly.find(id)
  end

  def notes
    project.notes.where(published: true).where.not(published_at: nil, internal: true)
  end
end
