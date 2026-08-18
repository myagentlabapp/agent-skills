-- 範例 DDL:小型電商「下單 → 出貨」核心
-- 對應 examples/ecommerce.erd.json

CREATE TABLE accounts (
  id          BIGINT       PRIMARY KEY AUTO_INCREMENT,
  email       VARCHAR(255) NOT NULL UNIQUE,
  status      VARCHAR(16)  NOT NULL DEFAULT 'active',  -- active | suspended | deleted
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
  id          BIGINT       PRIMARY KEY AUTO_INCREMENT,
  sku         VARCHAR(64)  NOT NULL UNIQUE,
  name        VARCHAR(255) NOT NULL,
  price_cents INT          NOT NULL,
  CHECK (price_cents >= 0)
);

CREATE TABLE carts (
  id          BIGINT       PRIMARY KEY AUTO_INCREMENT,
  account_id  BIGINT       NOT NULL,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
);

CREATE TABLE cart_items (
  cart_id     BIGINT       NOT NULL,
  product_id  BIGINT       NOT NULL,
  qty         INT          NOT NULL DEFAULT 1,
  PRIMARY KEY (cart_id, product_id),
  FOREIGN KEY (cart_id)    REFERENCES carts(id)    ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
);

CREATE TABLE orders (
  id           BIGINT       PRIMARY KEY AUTO_INCREMENT,
  account_id   BIGINT       NOT NULL,
  status       VARCHAR(16)  NOT NULL DEFAULT 'pending',  -- pending | paid | shipped | cancelled
  total_cents  INT          NOT NULL,
  placed_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE RESTRICT,
  INDEX idx_orders_account_placed (account_id, placed_at)
);

CREATE TABLE order_items (
  order_id     BIGINT       NOT NULL,
  product_id   BIGINT       NOT NULL,
  qty          INT          NOT NULL,
  unit_cents   INT          NOT NULL,  -- v3:下單當下快照,不再 join products
  PRIMARY KEY (order_id, product_id),
  FOREIGN KEY (order_id)   REFERENCES orders(id)   ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
);

CREATE TABLE shipments (
  id           BIGINT       PRIMARY KEY AUTO_INCREMENT,
  order_id     BIGINT       NOT NULL UNIQUE,            -- 1:1
  carrier      VARCHAR(32)  NOT NULL,
  tracking_no  VARCHAR(64),
  shipped_at   DATETIME,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);
