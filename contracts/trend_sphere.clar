;; TrendSphere - Fashion Discovery Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u401))
(define-constant err-already-exists (err u409))

;; Data Variables
(define-data-var last-outfit-id uint u0)
(define-data-var last-profile-id uint u0)

;; Data Maps
(define-map Profiles
    principal
    {
        id: uint,
        username: (string-ascii 50),
        bio: (string-ascii 500),
        points: uint
    }
)

(define-map Outfits
    uint  ;; outfit-id
    {
        creator: principal,
        title: (string-ascii 100),
        description: (string-ascii 500),
        image-url: (string-ascii 200),
        tags: (list 10 (string-ascii 20)),
        likes: uint,
        favorites: uint,
        created-at: uint
    }
)

(define-map UserLikes
    { user: principal, outfit-id: uint }
    bool
)

(define-map UserFavorites
    { user: principal, outfit-id: uint }
    bool
)

;; Profile Management
(define-public (create-profile (username (string-ascii 50)) (bio (string-ascii 500)))
    (let
        ((user tx-sender))
        (asserts! (is-none (map-get? Profiles user)) err-already-exists)
        (var-set last-profile-id (+ (var-get last-profile-id) u1))
        (ok (map-set Profiles 
            user
            {
                id: (var-get last-profile-id),
                username: username,
                bio: bio,
                points: u0
            }
        ))
    )
)

;; Outfit Management
(define-public (post-outfit 
    (title (string-ascii 100))
    (description (string-ascii 500))
    (image-url (string-ascii 200))
    (tags (list 10 (string-ascii 20))))
    (let
        ((user tx-sender)
         (outfit-id (+ (var-get last-outfit-id) u1)))
        (asserts! (is-some (map-get? Profiles user)) err-unauthorized)
        (var-set last-outfit-id outfit-id)
        (ok (map-set Outfits
            outfit-id
            {
                creator: user,
                title: title,
                description: description,
                image-url: image-url,
                tags: tags,
                likes: u0,
                favorites: u0,
                created-at: block-height
            }
        ))
    )
)

;; Engagement Functions
(define-public (like-outfit (outfit-id uint))
    (let
        ((user tx-sender)
         (outfit (unwrap! (map-get? Outfits outfit-id) err-not-found))
         (like-key {user: user, outfit-id: outfit-id}))
        
        (asserts! (is-none (map-get? UserLikes like-key)) err-already-exists)
        
        (map-set UserLikes like-key true)
        (map-set Outfits
            outfit-id
            (merge outfit {likes: (+ (get likes outfit) u1)})
        )
        (add-points (get creator outfit) u1)
        (ok true)
    )
)

(define-public (favorite-outfit (outfit-id uint))
    (let
        ((user tx-sender)
         (outfit (unwrap! (map-get? Outfits outfit-id) err-not-found))
         (fav-key {user: user, outfit-id: outfit-id}))
        
        (asserts! (is-none (map-get? UserFavorites fav-key)) err-already-exists)
        
        (map-set UserFavorites fav-key true)
        (map-set Outfits
            outfit-id
            (merge outfit {favorites: (+ (get favorites outfit) u1)})
        )
        (add-points (get creator outfit) u2)
        (ok true)
    )
)

;; Helper Functions
(define-private (add-points (user principal) (amount uint))
    (match (map-get? Profiles user)
        profile (map-set Profiles
            user
            (merge profile {points: (+ (get points profile) amount)}))
        false
    )
)

;; Read-Only Functions
(define-read-only (get-profile (user principal))
    (ok (map-get? Profiles user))
)

(define-read-only (get-outfit (outfit-id uint))
    (ok (map-get? Outfits outfit-id))
)

(define-read-only (get-user-points (user principal))
    (match (map-get? Profiles user)
        profile (ok (get points profile))
        (err err-not-found)
    )
)