class SemestersController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_to do |format|
      format.json { render :json => { :success => false }, :status => :not_found }
      format.ext_json { render :json => { :success => false }, :status => :not_found }
      format.ext_json_html { render :json => ERB::Util::html_escape({ :success => false }.to_json), :status => :not_found }
    end
  end

  before_filter :find_semester, :only => [ :show, :update, :edit ]

  def index
    @user = current_user
    @semesters = Semester.find(:all, :order => 'utc_starts_at desc')
  end

  def show
    @courses = @semester.courses
  end

  def new
    @semester = Semester.new
  end

  def create
    @semester = Semester.new
    @semester.update_attributes(params[:semester])
    @semester.save
    redirect_to :action => :index
  end

  def edit
  end

  def update
  end

protected

  def find_semester
    @semester = Semester.find(params[:id])
  end
end
