class Challenge::Cell::ChallengeSubnav < Challenge::Cell

  def show
    render :challenge_subnav
  end

  def challenge
    model
  end

  def current_tab
    case controller.controller_name
    when 'challenges'
      'overview'
    when 'leaderboards'
      'leaderboard'
    when 'topics'
      'discussion'
    when 'dataset_files'
      'dataset'
    end
  end

  def tab_class(tab)
    if tab == current_tab
      return 'active'
    else
      return ''
    end
  end

end
