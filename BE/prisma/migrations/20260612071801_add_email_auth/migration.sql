-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_users" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "student_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "google_sub" TEXT,
    "is_admin" BOOLEAN NOT NULL DEFAULT false,
    "phone" TEXT,
    "fcm_token" TEXT,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO "new_users" ("created_at", "email", "fcm_token", "google_sub", "id", "name", "phone", "student_id") SELECT "created_at", "email", "fcm_token", "google_sub", "id", "name", "phone", "student_id" FROM "users";
DROP TABLE "users";
ALTER TABLE "new_users" RENAME TO "users";
CREATE UNIQUE INDEX "users_student_id_key" ON "users"("student_id");
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");
CREATE UNIQUE INDEX "users_google_sub_key" ON "users"("google_sub");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
