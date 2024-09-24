-- Users table
CREATE TABLE users (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    username NVARCHAR(50) UNIQUE NOT NULL,
    email NVARCHAR(100) UNIQUE NOT NULL,
    password_hash NVARCHAR(255) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    last_login DATETIME2 NULL,
    is_active BIT DEFAULT 1
);
CREATE INDEX idx_username ON users(username);
CREATE INDEX idx_email ON users(email);

-- User profiles table
CREATE TABLE user_profiles (
    profile_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT UNIQUE,
    full_name NVARCHAR(100),
    bio NVARCHAR(MAX),
    avatar_url NVARCHAR(255),
    location NVARCHAR(100),
    website NVARCHAR(255),
    CONSTRAINT FK_UserProfiles_Users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Categories table
CREATE TABLE categories (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(50) NOT NULL,
    description NVARCHAR(MAX),
    parent_category_id INT,
    CONSTRAINT FK_Categories_ParentCategory FOREIGN KEY (parent_category_id) REFERENCES categories(category_id) 
);

-- Forums table
CREATE TABLE forums (
    forum_id INT IDENTITY(1,1) PRIMARY KEY,
    category_id INT,
    name NVARCHAR(100) NOT NULL,
    description NVARCHAR(MAX),
    created_at DATETIME2 DEFAULT GETDATE(),
    is_active BIT DEFAULT 1,
    CONSTRAINT FK_Forums_Categories FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE
);
CREATE INDEX idx_category_id ON forums(category_id);

-- Posts table
CREATE TABLE posts (
    post_id INT IDENTITY(1,1) PRIMARY KEY,
    forum_id INT,
    user_id INT,
    title NVARCHAR(255) NOT NULL,
    content NVARCHAR(MAX) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 NULL,
    view_count INT DEFAULT 0,
    is_sticky BIT DEFAULT 0,
    is_locked BIT DEFAULT 0,
    CONSTRAINT FK_Posts_Forums FOREIGN KEY (forum_id) REFERENCES forums(forum_id) ON DELETE CASCADE,
    CONSTRAINT FK_Posts_Users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);
CREATE INDEX idx_forum_id ON posts(forum_id);
CREATE INDEX idx_user_id ON posts(user_id);


-- Comments table
CREATE TABLE comments (
    comment_id INT IDENTITY(1,1) PRIMARY KEY,
    post_id INT,
    user_id INT,
    content NVARCHAR(MAX) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 NULL,
    parent_comment_id INT,
    CONSTRAINT FK_Comments_Posts FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
    CONSTRAINT FK_Comments_Users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
   -- CONSTRAINT FK_Comments_ParentComments FOREIGN KEY (parent_comment_id) REFERENCES comments(comment_id) ON DELETE CASCADE
);
CREATE INDEX idx_post_id ON comments(post_id);
CREATE INDEX idx_user_id ON comments(user_id);


-- Tags table
CREATE TABLE tags (
    tag_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(50) UNIQUE NOT NULL
);
CREATE INDEX idx_tag_name ON tags(name);

-- Post-Tag relationship table
CREATE TABLE post_tags (
    post_id INT,
    tag_id INT,
    PRIMARY KEY (post_id, tag_id),
    CONSTRAINT FK_PostTags_Posts FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
    CONSTRAINT FK_PostTags_Tags FOREIGN KEY (tag_id) REFERENCES tags(tag_id) ON DELETE CASCADE
);
CREATE INDEX idx_tag_id ON post_tags(tag_id);

-- Private messages table
CREATE TABLE private_messages (
    message_id INT IDENTITY(1,1) PRIMARY KEY,
    sender_id INT,
    recipient_id INT,
    subject NVARCHAR(255) NOT NULL,
    content NVARCHAR(MAX) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    is_read BIT DEFAULT 0,
    CONSTRAINT FK_PrivateMessages_Sender FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE SET NULL,
    --CONSTRAINT FK_PrivateMessages_Recipient FOREIGN KEY (recipient_id) REFERENCES users(user_id) ON DELETE SET NULL
);
CREATE INDEX idx_sender_id ON private_messages(sender_id);
CREATE INDEX idx_recipient_id ON private_messages(recipient_id);

-- Partitioning for posts table (example for date-based partitioning)
-- Note: SQL Server requires Enterprise edition for table partitioning
-- This is a simplified example and may need to be adjusted based on your specific SQL Server version and edition
CREATE PARTITION FUNCTION PF_PostsByDate (DATETIME2)
AS RANGE RIGHT FOR VALUES 
('2023-01-01', '2023-04-01', '2023-07-01', '2023-10-01', '2024-01-01');

CREATE PARTITION SCHEME PS_PostsByDate
AS PARTITION PF_PostsByDate
ALL TO ([PRIMARY]);

-- You would then need to create a new partitioned table and migrate data from the original posts table
-- This is a simplified example and should be carefully implemented in a production environment
CREATE TABLE posts_partitioned (
    post_id INT IDENTITY(1,1),
    forum_id INT,
    user_id INT,
    title NVARCHAR(255) NOT NULL,
    content NVARCHAR(MAX) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 NULL,
    view_count INT DEFAULT 0,
    is_sticky BIT DEFAULT 0,
    is_locked BIT DEFAULT 0,
    CONSTRAINT PK_PostsPartitioned PRIMARY KEY CLUSTERED (post_id, created_at)
) ON PS_PostsByDate(created_at);