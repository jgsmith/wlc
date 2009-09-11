class AssignmentsController < ApplicationController

  before_filter CASClient::Frameworks::Rails::Filter

  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_to do |format|
      format.json { render :json => { :success => false }, :status => :not_found }
      format.ext_json { render :json => { :success => false }, :status => :not_found }
    end
  end

  before_filter :find_assignment, :only => [ :show, :update ]

  def show
    @user = current_user
    if @assignment.course.user == @user
      # we want to show instructor view of assignment
      render :action => 'show_instructor'
    elsif @assignment.course.is_student?(@user)
      # we show student view of assignment (default)
    else
      render :text => 'Forbidden.', :status => 403
    end
  end

  def update
    @user = current_user

    if @assignment.course.user == @user
      if !params[:assignment][:author_eval].nil?
        author_eval = {
          :instructions => params[:assignment][:author_eval][:instructions],
          :prompts => hash_to_array(params[:assignment][:author_eval][:prompts])
        }

        author_eval[:prompts].each do |p|
          p[:responses] = hash_to_array(p[:responses])
        end

        params[:assignment][:author_eval] = author_eval
      end

      if !params[:assignment][:participant_eval].nil?
        participant_eval = {
          :instructions => params[:assignment][:participant_eval][:instructions],
          :prompts => hash_to_array(params[:assignment][:participant_eval][:prompts])
        }

        participant_eval[:prompts].each do |p|
          p[:responses] = hash_to_array(p[:responses])
        end

        params[:assignment][:participant_eval] = participant_eval
      end

      params[:assignment][:eval_duration] = params[:assignment][:eval_duration].to_i * 60 unless params[:assignment][:eval_duration].blank?;

      respond_to do |format|
        format.ext_json { render :json => @assignment.to_ext_json(:success => @assignment.update_attributes(params[:assignment])) }
      end
    else
      respond_to do |format|
        format.ext_json { render :json => { :success => false } }
      end
    end
  end

protected

  def hash_to_array(h)
    r = [ ]
    h.keys.sort_by{|a,b| a.to_i <=> b.to_i}.each do |k|
      r << h[k]
    end
    return r
  end

  def find_assignment
    @assignment = Assignment.find(params[:id])
  end
end
