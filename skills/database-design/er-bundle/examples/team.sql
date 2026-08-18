-- 範例 DDL:users ↔ teams 互相可選引用
-- 對應 examples/team.erd.json,用於展示 0:1 與 0:N cardinality
--
-- 設計重點:
--   * users.team_id 可為 NULL → 使用者不一定屬於團隊
--   * teams.lead_user_id 可為 NULL → 團隊不一定有 lead
--   * 兩者構成一個「可選的雙向關聯」,常見於組織管理場景

CREATE TABLE users (
  id          BIGINT       PRIMARY KEY AUTO_INCREMENT,
  email       VARCHAR(255) NOT NULL UNIQUE,
  display_name VARCHAR(255) NOT NULL,
  team_id     BIGINT       NULL,                     -- 可選歸屬
  joined_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE SET NULL
);

CREATE TABLE teams (
  id            BIGINT       PRIMARY KEY AUTO_INCREMENT,
  name          VARCHAR(255) NOT NULL UNIQUE,
  lead_user_id  BIGINT       NULL,                   -- 可選的 lead
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (lead_user_id) REFERENCES users(id) ON DELETE SET NULL
);
