class RubricsOwnedByCourses < ActiveRecord::Migration
  def self.up
    add_column :rubrics, :course_id, :integer

    # make rubrics be owned by the first course of the user
    Rubric.all.each do |rubric|
      if !rubric.user.nil?
        rubric.course = rubric.user.courses.first
        rubric.save
      end
    end

    remove_column :rubrics, :user_id
  end

  def self.down
    add_column :rubrics, :user_id, :integer

    Rubric.all.each do |rubric|
      if !rubric.course.nil?
        rubric.user = rubric.course.user
        rubric.save
      end
    end

    remove_column :rubrics, :course_id
  end
end
