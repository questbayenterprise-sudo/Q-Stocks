
-- Update venue owner by username
UPDATE venues SET created_by = u.id
FROM users u
WHERE u.username = 'subhashbalajimswp2@gmail.com'
AND venues.id = 1; -- venue_id

-- Also update user_venue_mapping
INSERT INTO user_venue_mapping (user_id, venue_id)
SELECT u.id, 1
FROM users u
WHERE u.username = 'subhashbalajimswp2@gmail.com'
AND NOT EXISTS (
    SELECT 1 FROM user_venue_mapping m WHERE m.user_id = u.id AND m.venue_id = 1
);
