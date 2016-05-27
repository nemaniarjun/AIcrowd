class Grader
  include HTTParty
  debug_output $stdout
  #base_uri "#{ENV["GRADER"]}/api/v1/"
  base_uri "http://54.184.7.125/api/v1"

  def initialize(submission_id)
    @submission = Submission.find(submission_id)
  end


  def grade
    @body = api_body
    if @body
      response = call_grader
      evaluate_response(submission_id,response)
    else
      Submission.update(@submission_id, grading_status: 'failed', grading_message: 'Files were not received by server.')
      raise "Grader called for submission #{@submission_id} but key cannot be found"
    end
  end



  def call_grader
    begin
      response = self.class.post('/grade',@body)
      puts response
      #response = HTTParty.get("http://54.184.7.125/api/v1/plantvillage_evaluation?submission_id=#{submission_id}&submission_key=#{key}", timeout: 1200)
    rescue => e
      Submission.update(@submission_id, grading_status: 'failed', grading_message: 'Grading process system error.')
      raise e
    end
  end


  def evaluate_response(submission_id,response)
    r = response.parsed_response

    if response.code == 200
      if r["status"] == 'success'
        # update the submission
        Submission.update(submission_id, grading_status: 'graded', score: r["f1-score"], score_secondary: r["log-loss"])
      else
        Submission.update(submission_id, grading_status: 'failed', grading_message: r["message"])
       # TODO email the participant
      end
    else
      Submission.update(submission_id, grading_status: 'failed', grading_message: 'Grading process system error.')
      raise "API call to grader failed #{response.inspect}"
    end
  end

  private

  def api_body
    c = @submission.challenge
    body = { body: { primary_grader: c.primary_grader,
                         secondary_grader: c.secondary_grader,
                         primary_sort_order: c.primary_sort_order_cd,
                         secondary_sort_order: c.secondary_sort_order_cd,
                         grading_factor: c.grading_factor,
                         reference_key: get_reference_key,
                         participant_key: get_participant_key }}
  end


  def get_participant_key
    key = @submission.submission_files.first.submission_file_s3_key
  end


  def get_reference_key
    'abcd'
  end

end

# TESTS
# 1) Invalid header format
# curl "http://54.184.7.125/api/v1/plantvillage_evaluation?submission_id=234&submission_key=submission_files/3da7e968-94b2-4ff5-a7a7-29eab1cffaf9/submission.csv"


# 2) Successful grading
# curl "http://54.184.7.125/api/v1/plantvillage_evaluation?submission_id=234&submission_key=submission_files/2af25ed3-3bf2-4b7e-885d-f7f65755087a/classification.csv"



#c
# curl -X GET -G http://54.184.7.125/api/v1/plantvillage_evaluation -d "id=234" -d "submission_key=submission_files/3da7e968-94b2-4ff5-a7a7-29eab1cffaf9/submission.csv"
