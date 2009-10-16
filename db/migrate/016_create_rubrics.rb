class CreateRubrics < ActiveRecord::Migration
  def self.up
    # we want to go through all of the records and change them
    
    add_column :assignment_modules, :author_rubric_id, :integer
    add_column :assignment_modules, :participant_rubric_id, :integer

    add_column :assignments, :author_rubric_id, :integer
    add_column :assignments, :participant_rubric_id, :integer

    add_column :assignments, :scores_final, :boolean

    add_column :assignment_templates, :author_rubric_id, :integer
    add_column :assignment_templates, :participant_rubric_id, :integer

    add_column :assignment_template_modules, :author_rubric_id, :integer
    add_column :assignment_template_modules, :participant_rubric_id, :integer

    rename_column :assignments, :author_eval, :old_author_eval
    rename_column :assignments, :participant_eval, :old_participant_eval

    rename_column :assignment_modules, :author_eval, :old_author_eval
    rename_column :assignment_modules, :participant_eval, :old_participant_eval

    rename_column :assignment_templates, :author_eval, :old_author_eval
    rename_column :assignment_templates, :participant_eval, :old_participant_eval

    rename_column :assignment_template_modules, :author_eval, :old_author_eval
    rename_column :assignment_template_modules, :participant_eval, :old_participant_eval

    add_column :assignments, :calculate_trust, :boolean
    add_column :assignments, :use_trust, :boolean
    add_column :assignments, :trust_uses_self_eval, :boolean
    # 0=arithmetic, 1=geometric, 2=harmonic
    add_column :assignments, :trust_mean, :integer
    add_column :assignments, :trust_fn, :text

    add_column :assignments, :scores_calculated, :boolean

    add_column :assignment_templates, :calculate_trust, :boolean
    add_column :assignment_templates, :use_trust, :boolean
    add_column :assignment_templates, :trust_uses_self_eval, :boolean
    add_column :assignment_templates, :trust_mean, :integer
    add_column :assignment_templates, :trust_fn, :text

    add_column :assignment_submissions, :author_eval_score, :float
    add_column :assignment_submissions, :score, :float
    add_column :assignment_submissions, :trust, :float
 
    add_column :assignment_participations, :author_eval_score, :float
    add_column :assignment_participations, :participant_eval_score, :float

    create_table :rubrics do |t|
      t.references :user
      t.string  :name
      t.text    :instructions
      t.text    :calculate_fn
      t.float   :minimum
      t.float   :floor
      t.float   :maximum
      t.float   :ceiling
      t.boolean :inclusive_minimum
      t.boolean :inclusive_maximum
      t.boolean :use_trust

      t.timestamps
    end

    create_table :prompts do |t|
      t.references :rubric
      t.integer    :position
      t.string     :prompt
      t.string     :tag

      t.timestamps
    end

    create_table :responses do |t|
      t.references :prompt
      t.integer    :position
      t.integer    :score
      t.string     :response

      t.timestamps
    end

    # first, create rubrics for each of the existing evals
    say_with_time "Updating rubrics..." do
      AssignmentModule.find(:all).each do |am|
        if am.old_author_eval && !am.old_author_eval.empty?
          am.author_rubric = create_rubric(am.old_author_eval)
          am.author_rubric.user = am.assignment.course.user
          am.author_rubric.name = (am.author_name || 'Author') + " Rubric for Assignment Module #" + am.id.to_s
          am.author_rubric.save
        end
        if am.old_participant_eval && !am.old_participant_eval.empty?
          am.participant_rubric = create_rubric(am.old_participant_eval)
          am.participant_rubric.user = am.assignment.course.user
          am.participant_rubric.name = (am.participant_name || "Participant") + " Rubric for Assignment Module #" + am.id.to_s
          am.participant_rubric.save
        end
        am.save
      end

      Assignment.find(:all).each do |a|
        if a.old_author_eval && !a.old_author_eval.empty?
          a.author_rubric = create_rubric(a.old_author_eval)
          a.author_rubric.user = a.course.user
          a.author_rubric.name = (a.author_name || 'Author') + " Rubric for Assignment Module #" + a.id.to_s
          a.author_rubric.save
        end
        if a.old_participant_eval && !a.old_participant_eval.empty?
          a.participant_rubric = create_rubric(a.old_participant_eval)
          a.participant_rubric.user = a.course.user
          a.participant_rubric.name = (a.eval_name || "Review") + " Rubric for Assignment #" + a.id.to_s
          a.participant_rubric.save
        end
        a.save
      end

      AssignmentTemplateModule.find(:all).each do |am|
        if am.old_author_eval && !am.old_author_eval.empty?
          am.author_rubric = create_rubric(am.old_author_eval)
          am.author_rubric.user = am.assignment_template.user
          am.author_rubric.name = (am.author_name || 'Author') + " Rubric for Assignment Template Module #" + am.id.to_s
          am.author_rubric.save
        end
        if am.old_participant_eval && !am.old_participant_eval.empty?
          am.participant_rubric = create_rubric(am.participant_eval)
          am.participant_rubric.user = am.assignment_template.user
          am.participant_rubric.name = (am.participant_name || "Participant") + " Rubric for Assignment Template Module #" + am.id.to_s
          am.participant_rubric.save
        end
        am.save
      end

      AssignmentTemplate.find(:all).each do |a|
        if a.old_author_eval && !a.old_author_eval.empty?
          a.author_rubric = create_rubric(a.old_author_eval)
          a.author_rubric.user = a.user
          a.author_rubric.name = (a.author_name || 'Author') + " Rubric for Assignment Module #" + a.id.to_s
          a.author_rubric.save
        end
        if a.old_participant_eval && !a.old_participant_eval.empty?
          a.participant_rubric = create_rubric(a.old_participant_eval)
          a.participant_rubric.user = a.user
          a.participant_rubric.name = (a.participant_name || "Participant") + " Rubric for Assignment Template #" + a.id.to_s
          a.participant_rubric.save
        end
        a.save
      end
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, "Not yet"

    # need to update old_ attributes with rubric.to_h

    remove_column :assignment_modules, :author_rubric_id
    remove_column :assignment_modules, :participant_rubric_id

    remove_column :assignments, :author_rubric_id
    remove_column :assignments, :participant_rubric_id

    remove_column :assignment_templates, :author_rubric_id
    remove_column :assignment_templates, :participant_rubric_id

    remove_column :assignment_template_modules, :author_rubric_id
    remove_column :assignment_template_modules, :participant_rubric_id

    rename_column :assignments, :old_author_eval, :author_eval
    rename_column :assignments, :old_participant_eval, :participant_eval

    rename_column :assignment_moduless, :old_author_eval, :author_eval
    rename_column :assignment_moduless, :old_participant_eval, :participant_eval

    rename_column :assignment_templates, :old_author_eval, :author_eval
    rename_column :assignment_templates, :old_participant_eval, :participant_eval

    rename_column :assignment_template_moduless, :old_author_eval, :author_eval
    rename_column :assignment_template_moduless, :old_participant_eval, :participant_eval

    drop_table :responses
    drop_table :prompts
    drop_table :rubrics
  end

  def self.create_rubric(config)
    rubric = Rubric.new
    rubric.instructions = config[:instructions]
    rubric.save!
    p_pos = 1
    config[:prompts].each do |p|
      prompt = Prompt.new
      prompt.rubric = rubric
      prompt.prompt = p[:prompt]
      prompt.tag = p[:tag]
      prompt.position = p_pos
      prompt.save!
      p_pos = p_pos + 1
      r_pos = 1
      p[:responses].each do |r|
        response = Response.new
        response.prompt = prompt
        response.response = r[:response]
        response.score = r[:score]
        response.position = r_pos
        response.save!
        r_pos = r_pos + 1
      end
    end
    return rubric
  end
end
