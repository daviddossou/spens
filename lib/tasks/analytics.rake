# frozen_string_literal: true

namespace :analytics do
  # One-off: onboarding answers given before they were tracked. Writes them on each PostHog
  # person (from the user's first own space) and on every space group, and replays the chosen
  # problems as "onboarding_goal_chosen" dated at the space's creation. Safe to re-run.
  desc "Backfill onboarding answers to PostHog persons, groups and goal events"
  task backfill_onboarding: :environment do
    Space.find_each { |space| Analytics.group_identify(space) }

    User.find_each do |user|
      space = user.owned_spaces.order(:created_at).first or next

      Analytics.set_person(user, Analytics.onboarding_person_properties(space))
      Array(space.financial_goals).each do |goal|
        Analytics.track_once("#{space.id}:#{goal}", space.created_at, user, "onboarding_goal_chosen",
                             goal: goal, first_space: true, from_landing: false, space_id: space.id)
      end
    end
  end
end
