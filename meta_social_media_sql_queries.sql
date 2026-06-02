 -- =====================================================
-- META SOCIAL MEDIA ANALYTICS PROJECT
-- Author: Suryaprakash Reddy Muddireddy
-- Total Questions Solved: 15
-- =====================================================

-- =====================================================
-- Question 1
-- Return active users with their registration details.
-- =====================================================

SELECT username,
       email,
       first_name||' '||last_name AS full_name,
       country,
       registration_date
FROM users
WHERE status ='active';


-- =====================================================
-- Question 2
-- Return post counts for users who have created at least one post.
-- =====================================================

SELECT u.username,
       u.first_name||' '||u.last_name AS full_name,
       COUNT(p.post_id) AS post_count
FROM users u
JOIN posts p ON u.user_id = p.user_id
GROUP BY u.username;


-- =====================================================
-- Question 3
-- Return top performing posts by likes.
-- =====================================================

SELECT p.post_id,
       u.username,
       TRIM(p.content) AS post_content_preview,
       p.likes_count
FROM users u
JOIN posts p ON u.user_id = p.user_id
GROUP BY p.post_id, u.username
ORDER BY p.likes_count DESC
LIMIT 10;

HAVING COUNT(p.post_id) >= 1;

-- =====================================================
-- Question 4
-- Return accepted friendships.
-- =====================================================

SELECT
  u1.first_name || ' ' || u1.last_name AS friend1_name,
  u2.first_name || ' ' || u2.last_name AS friend2_name,
  f.accepted_at
FROM friendships f
JOIN users u1 ON f.user_id_1 = u1.user_id
JOIN users u2 ON f.user_id_2 = u2.user_id
WHERE f.accepted_at IS NOT NULL
ORDER BY f.accepted_at DESC;

-- =====================================================
-- Question 5
-- Return all public groups with their basic information.
-- =====================================================

SELECT g.group_name,
       g.description,
       u.username AS creator_username,
       g.member_count,
       g.created_at
FROM groups g
JOIN users u ON g.created_by = u.user_id
WHERE g.privacy='public';

-- =====================================================
-- Question 6
-- Return all verified pages with category and follower count.
-- =====================================================

SELECT p.page_name,
       p.category,
       p.followers_count,
       u.username AS creator_username
FROM pages p
JOIN users u ON p.created_by = u.user_id
WHERE p.verified = 1
ORDER BY p.followers_count DESC;

-- =====================================================
-- Question 7
-- Return total engagement metrics for each user.
-- =====================================================

SELECT
  u.username,
  COUNT(DISTINCT p.post_id) AS total_posts,
  COUNT(DISTINCT c.comment_id) AS total_comments,
  COUNT(DISTINCT l.like_id) AS total_likes_given,
  COUNT(DISTINCT p.post_id) +
  COUNT(DISTINCT c.comment_id) +
  COUNT(DISTINCT l.like_id) AS total_engagement
FROM users u
LEFT JOIN posts p ON u.user_id = p.user_id
LEFT JOIN comments c ON u.user_id = c.user_id
LEFT JOIN likes l ON u.user_id = l.user_id
GROUP BY u.username
ORDER BY total_engagement DESC;

-- =====================================================
-- Question 8
-- Return users whose post count is above average.
-- =====================================================

WITH user_posts AS (
    SELECT
      u.user_id,
      u.username,
      COUNT(p.post_id) AS post_count
    FROM users u
    LEFT JOIN posts p ON u.user_id = p.user_id
    GROUP BY u.user_id, u.username
),
avg_posts AS (
    SELECT AVG(post_count) AS avg_post_count
    FROM user_posts
)
SELECT
  up.username,
  up.post_count,
  ROUND(ap.avg_post_count,2) AS avg_post_count,
  up.post_count - ROUND(ap.avg_post_count,2) AS difference_from_avg
FROM user_posts up
CROSS JOIN avg_posts ap
WHERE up.post_count > ap.avg_post_count
ORDER BY up.post_count DESC;

-- =====================================================
-- Question 9
-- Return average time between posts.
-- =====================================================

WITH post_gaps AS (
    SELECT
      user_id,
      created_at,
      LAG(created_at) OVER(
        PARTITION BY user_id
        ORDER BY created_at
      ) AS prev_post_date,
      julianday(created_at) -
      julianday(
        LAG(created_at) OVER(
          PARTITION BY user_id
          ORDER BY created_at
        )
      ) AS gap_days
    FROM posts
),
user_gap_stats AS (
    SELECT
      user_id,
      COUNT(*) + 1 AS total_posts,
      ROUND(AVG(gap_days),1) AS avg_gap_days
    FROM post_gaps
    WHERE prev_post_date IS NOT NULL
    GROUP BY user_id
)
SELECT
  u.username,
  ugs.total_posts,
  ugs.avg_gap_days
FROM user_gap_stats ugs
INNER JOIN users u
ON ugs.user_id = u.user_id
WHERE ugs.total_posts >= 2
ORDER BY ugs.avg_gap_days ASC;

-- =====================================================
-- Question 10
-- Return groups ranked by activity level.
-- =====================================================

SELECT
  g.group_name,
  g.member_count,
  COUNT(p.post_id) AS total_member_posts,
  RANK() OVER(
    ORDER BY COUNT(p.post_id) DESC
  ) AS activity_rank
FROM groups g
LEFT JOIN group_members gm
ON g.group_id = gm.group_id
LEFT JOIN posts p
ON gm.user_id = p.user_id
GROUP BY
  g.group_id,
  g.group_name,
  g.member_count
ORDER BY activity_rank;

-- =====================================================
-- Question 11
-- Return ad campaign performance metrics.
-- =====================================================

SELECT
  a.ad_title,
  p.page_name,
  a.impressions,
  a.clicks,
  a.conversions,
  ROUND((a.clicks * 100.0 / a.impressions),2) AS ctr_percentage,
  ROUND((a.conversions * 100.0 / NULLIF(a.clicks,0)),2) AS conversion_rate
FROM ads a
INNER JOIN pages p
ON a.page_id = p.page_id
WHERE a.impressions >= 1000
ORDER BY conversion_rate DESC;

-- =====================================================
-- Question 12
-- Return the friendship network analysis.
-- =====================================================

WITH user_friends AS (
    SELECT
      user_id_1 AS user_id,
      user_id_2 AS friend_id
    FROM friendships
    WHERE status = 'accepted'

    UNION ALL

    SELECT
      user_id_2 AS user_id,
      user_id_1 AS friend_id
    FROM friendships
    WHERE status = 'accepted'
),
friend_counts AS (
    SELECT
      user_id,
      COUNT(friend_id) AS total_friends
    FROM user_friends
    GROUP BY user_id
),
mutual_friends AS (
    SELECT
      uf1.user_id,
      uf1.friend_id,
      COUNT(DISTINCT uf3.friend_id) AS mutual_count
    FROM user_friends uf1
    INNER JOIN user_friends uf2
      ON uf1.friend_id = uf2.user_id
    INNER JOIN user_friends uf3
      ON uf1.user_id = uf3.user_id
     AND uf2.friend_id = uf3.friend_id
    WHERE uf2.friend_id != uf1.user_id
    GROUP BY
      uf1.user_id,
      uf1.friend_id
),
max_mutuals AS (
    SELECT
      user_id,
      MAX(mutual_count) AS max_mutual_friends
    FROM mutual_friends
    GROUP BY user_id
)
SELECT
  u.username,
  fc.total_friends,
  CAST(COALESCE(mm.max_mutual_friends, 0) AS INTEGER) AS max_mutual_friends,
  RANK() OVER (
    ORDER BY
      fc.total_friends DESC,
      COALESCE(mm.max_mutual_friends, 0) DESC
  ) AS network_rank
FROM users u
INNER JOIN friend_counts fc
  ON u.user_id = fc.user_id
LEFT JOIN max_mutuals mm
  ON u.user_id = mm.user_id
ORDER BY
  network_rank,
  u.username;

-- =====================================================
-- Question 13
-- Return the content virality score analysis.
-- =====================================================

WITH post_engagement AS (
    SELECT
      p.post_id,
      u.username,
      SUBSTR(p.content, 1, 40) AS content_preview,
      (p.likes_count + p.comments_count + p.shares_count) AS total_engagement,
      ROUND(
        (p.likes_count + p.comments_count + p.shares_count) * 1.0 /
        NULLIF(p.likes_count, 0),
        2
      ) AS engagement_rate,
      p.shares_count * 2.0 +
      p.comments_count * 1.5 +
      p.likes_count AS weighted_engagement
    FROM posts p
    INNER JOIN users u
      ON p.user_id = u.user_id
    WHERE (p.likes_count + p.comments_count + p.shares_count) > 0
),
virality_calc AS (
    SELECT
      post_id,
      username,
      content_preview,
      total_engagement,
      engagement_rate,
      ROUND(
        (
          weighted_engagement /
          (
            SELECT MAX(weighted_engagement)
            FROM post_engagement
          )
        ) * 100,
        2
      ) AS virality_score
    FROM post_engagement
)
SELECT
  post_id,
  username,
  content_preview,
  total_engagement,
  engagement_rate,
  virality_score,
  RANK() OVER (
    ORDER BY virality_score DESC
  ) AS virality_rank
FROM virality_calc
ORDER BY virality_rank;

-- =====================================================
-- Question 14
-- Return the user influence score dashboard.
-- =====================================================

WITH user_posts AS (
    SELECT
      p.user_id,
      COUNT(p.post_id) AS total_posts,
      ROUND(
        AVG(p.likes_count + p.comments_count + p.shares_count),
        2
      ) AS avg_engagement_per_post,
      MAX(p.likes_count + p.comments_count + p.shares_count) AS max_engagement
    FROM posts p
    GROUP BY p.user_id
),
user_friends AS (
    SELECT
      user_id_1 AS user_id,
      user_id_2 AS friend_id
    FROM friendships
    WHERE status = 'accepted'

    UNION ALL

    SELECT
      user_id_2 AS user_id,
      user_id_1 AS friend_id
    FROM friendships
    WHERE status = 'accepted'
),
friend_counts AS (
    SELECT
      user_id,
      COUNT(friend_id) AS friend_count
    FROM user_friends
    GROUP BY user_id
),
influence_calc AS (
    SELECT
      u.user_id,
      u.username,
      COALESCE(up.total_posts, 0) AS total_posts,
      COALESCE(up.avg_engagement_per_post, 0) AS avg_engagement_per_post,
      COALESCE(fc.friend_count, 0) AS friend_count,
      ROUND(
        (
          COALESCE(up.total_posts, 0) * 10 +
          COALESCE(up.avg_engagement_per_post, 0) * 2 +
          COALESCE(fc.friend_count, 0) * 15 +
          COALESCE(up.max_engagement, 0) * 0.5
        ),
        2
      ) AS influence_score
    FROM users u
    LEFT JOIN user_posts up
      ON u.user_id = up.user_id
    LEFT JOIN friend_counts fc
      ON u.user_id = fc.user_id
    WHERE u.status = 'active'
)
SELECT
  username,
  total_posts,
  avg_engagement_per_post,
  friend_count,
  influence_score,
  RANK() OVER (
    ORDER BY influence_score DESC
  ) AS influence_rank
FROM influence_calc
ORDER BY influence_rank;

-- =====================================================
-- Question 15
-- Return the cross-platform engagement correlation output.
-- =====================================================

WITH user_activity AS (
    SELECT
      u.user_id,
      u.username,
      COUNT(DISTINCT p.post_id) AS posts_count,
      COUNT(DISTINCT c.comment_id) AS comments_count,
      COUNT(DISTINCT l.like_id) AS likes_count,
      COUNT(DISTINCT m.message_id) AS messages_count,
      COUNT(DISTINCT s.story_id) AS stories_count
    FROM users u
    LEFT JOIN posts p ON u.user_id = p.user_id
    LEFT JOIN comments c ON u.user_id = c.user_id
    LEFT JOIN likes l ON u.user_id = l.user_id
    LEFT JOIN messages m ON u.user_id = m.sender_id
    LEFT JOIN stories s ON u.user_id = s.user_id
    WHERE u.status = 'active'
    GROUP BY
      u.user_id,
      u.username
),
engagement_type AS (
    SELECT
      user_id,
      username,
      posts_count,
      comments_count,
      likes_count,
      messages_count,
      stories_count,
      CASE
        WHEN posts_count >= comments_count
         AND posts_count >= likes_count
         AND posts_count >= messages_count
         AND posts_count >= stories_count
          THEN 'Content Creator'
        WHEN comments_count >= posts_count
         AND comments_count >= likes_count
         AND comments_count >= messages_count
         AND comments_count >= stories_count
          THEN 'Commenter'
        WHEN likes_count >= posts_count
         AND likes_count >= comments_count
         AND likes_count >= messages_count
         AND likes_count >= stories_count
          THEN 'Liker'
        WHEN messages_count >= posts_count
         AND messages_count >= comments_count
         AND messages_count >= likes_count
         AND messages_count >= stories_count
          THEN 'Messenger'
        ELSE 'Story Viewer'
      END AS primary_engagement_type,
      (
        posts_count * 5 +
        comments_count * 3 +
        likes_count * 1 +
        messages_count * 2 +
        stories_count * 4
      ) AS total_activity_score
    FROM user_activity
)
SELECT
  username,
  posts_count,
  comments_count,
  likes_count,
  messages_count,
  stories_count,
  primary_engagement_type,
  RANK() OVER (
    ORDER BY total_activity_score DESC
  ) AS activity_rank
FROM engagement_type
ORDER BY activity_rank;
