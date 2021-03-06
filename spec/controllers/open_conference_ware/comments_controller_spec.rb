require 'spec_helper'

describe OpenConferenceWare::CommentsController do
  render_views
  fixtures :all
  routes { OpenConferenceWare::Engine.routes }

  before do
    @event = events(:open)
    @proposal = proposals(:quentin_widgets)
  end

  describe "index" do
    shared_examples_for "shared forbidden index behaviors" do
      describe "HTML" do
        before do
          get :index
        end

        it "should get redirect" do
          response.should be_redirect
        end
      end
    end

    shared_examples_for "shared allowed index behaviors" do
      describe "Atom" do
        it "should get error if not key was specified" do
          get :index, format: "atom"

          response.should_not be_success
          response.should_not be_redirect
        end

        it "should get error if key is wrong" do
          get :index, format: "atom", secret: "MEOW"

          response.should_not be_success
          response.should_not be_redirect
        end

        it "should get data if key is right" do
          get :index, format: "atom", secret: OpenConferenceWare::CommentsController::SECRET

          response.should be_success
          comments = assigns(:comments)
          struct = Hash.from_xml(response.body)
          struct['feed']['entry'].size.should == comments.size
        end
      end
    end

    describe "anonymous user" do
      it_should_behave_like "shared forbidden index behaviors"
      it_should_behave_like "shared allowed index behaviors"
    end

    describe "mortal user" do
      before do
        login_as :quentin
      end

      it_should_behave_like "shared forbidden index behaviors"
      it_should_behave_like "shared allowed index behaviors"
    end

    describe "admin user" do
      before do
        login_as :aaron
      end

      after do
        logout
      end

      it_should_behave_like "shared allowed index behaviors"

      describe "HTML" do
        before do
          get :index
        end

        it "should display comments" do
          response.should be_success
          assigns(:comments).size.should > 0
        end
      end
    end
  end

  describe "create" do
    it "should reject comments from bots" do
      post :create, proposal_id: @proposal.to_param, quagmire: "omg"

      flash[:failure].should match(/robot/i)
      response.should be_redirect
    end

    it "should fail on empty comment" do
      email = "bubba@smith.com"
      message = "Yo"
      post :create, proposal_id: @proposal.to_param, comment: {email: "bubba@smith.com"}

      flash.keys.should include(:failure)
      assigns(:comment).should_not be_valid
    end

    it "should fail on incomplete comment" do
      post :create, proposal_id: @proposal.to_param, comment: {email: "bubba@smith.com", message: ""}

      flash.keys.should include(:failure)
      assigns(:comment).should_not be_valid
    end

    it "should create new comment" do
      email = "bubba@smith.com"
      message = "Yo"
      post :create, proposal_id: @proposal.to_param, comment: {email: email, message: message}

      assigns(:comment).should be_valid
      flash.keys.should_not include(:failure)
      response.should redirect_to(proposal_url(@proposal, commented: true))
    end

    it "should assign email if logged in" do
      login_as :quentin
      post :create, proposal_id: @proposal.to_param, comment: {message: "Yo"}

      comment = assigns(:comment)
      comment.email.should == users(:quentin).email
    end
  end

  describe "destroy" do
    it "should destroy" do
      login_as :aaron
      comment = comments(:clio_chupacabras_fbi)
      Comment.should_receive(:find).with(comment.to_param).and_return(comment)
      comment.should_receive(:destroy)
      delete :destroy, id: comment.to_param, format: :html

      flash.keys.should include(:success)
      # response.should be_redirect # TODO why not?
    end
  end
end
