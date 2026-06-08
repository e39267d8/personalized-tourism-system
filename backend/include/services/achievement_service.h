#pragma once

#include "crow.h"
#include "db/postgres.h"
#include "services/auth_service.h"

#include <optional>
#include <string>

namespace tourism::services {

struct CheckinInput {
    bool has_location = false;
    double latitude = 0.0;
    double longitude = 0.0;
};

struct BadgeRedemptionInput {
    int achievement_id = 0;
    std::string recipient_name;
    std::string phone;
    std::string address;
    std::string note;
};

struct ReviewDecisionInput {
    std::string status;
    std::string review_note;
};

void ensure_achievement_schema(tourism::db::PgConnection& db);
void seed_default_achievements(tourism::db::PgConnection& db);
void evaluate_user_achievements(tourism::db::PgConnection& db, int user_id);

crow::json::wvalue achievements_overview(tourism::db::PgConnection& db, std::optional<int> user_id);
crow::json::wvalue create_scenic_checkin(tourism::db::PgConnection& db, int user_id, int scenic_spot_id, const CheckinInput& input);
crow::json::wvalue claim_achievement_reward(tourism::db::PgConnection& db, int user_id, int achievement_id);
crow::json::wvalue user_collectibles(tourism::db::PgConnection& db, int user_id);
crow::json::wvalue collectible_detail(tourism::db::PgConnection& db, int user_id, int collectible_id);
crow::json::wvalue create_badge_redemption(tourism::db::PgConnection& db, int user_id, const BadgeRedemptionInput& input);
crow::json::wvalue user_badge_redemptions(tourism::db::PgConnection& db, int user_id);
crow::json::wvalue submit_achievement_review(tourism::db::PgConnection& db, int user_id, int diary_id);
crow::json::wvalue review_submissions(tourism::db::PgConnection& db, const std::string& status);
crow::json::wvalue decide_review_submission(tourism::db::PgConnection& db, int submission_id, const ReviewDecisionInput& input);
bool can_review_achievements(const AuthUser& user);

} // namespace tourism::services
