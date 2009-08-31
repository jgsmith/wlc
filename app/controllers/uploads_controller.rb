class UploadsController < ApplicationController
  def show
    @user = current_user
    @upload = Upload.find(params[:id])
    if @upload.can_user_view_upload?(@user)
      # take advantage of lighttpd's forwarding mechanism if we can
      send_file @upload.path, 
        :type => @upload.content_type,
        :filename => @upload.download_name
    else
      render :text => 'Forbidden.', :status => 403
    end
  end
end
