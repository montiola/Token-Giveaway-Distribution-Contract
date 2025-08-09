;; Token Giveaway Distribution Contract

;; Define constants
(define-constant DEPLOYER-PRINCIPAL tx-sender)
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-REWARD-ALREADY-COLLECTED (err u101))
(define-constant ERR-USER-NOT-WHITELISTED (err u102))
(define-constant ERR-INSUFFICIENT-CONTRACT-FUNDS (err u103))
(define-constant ERR-GIVEAWAY-SUSPENDED (err u104))
(define-constant ERR-INVALID-REWARD-AMOUNT (err u105))
(define-constant ERR-WITHDRAWAL-PERIOD-ACTIVE (err u106))
(define-constant ERR-INVALID-USER-ADDRESS (err u107))
(define-constant ERR-INVALID-TIME-PERIOD (err u108))

;; Define data variables
(define-data-var giveaway-status-active bool true)
(define-data-var tokens-already-distributed uint u0)
(define-data-var reward-per-user uint u100)
(define-data-var giveaway-launch-block uint block-height)
(define-data-var withdrawal-time-limit uint u10000) ;; Number of blocks after which unused tokens can be withdrawn

;; Define data maps
(define-map whitelisted-users principal bool)
(define-map collected-rewards principal uint)

;; Define fungible token
(define-fungible-token token-giveaway-distribution)

;; Define events
(define-data-var current-event-id uint u0)
(define-map event-log uint {event-type: (string-ascii 20), data: (string-ascii 256)})

;; Event logging function
(define-private (record-event (event-type (string-ascii 20)) (data (string-ascii 256)))
  (let ((event-id (var-get current-event-id)))
    (map-set event-log event-id {event-type: event-type, data: data})
    (var-set current-event-id (+ event-id u1))
    event-id))

;; Admin functions

(define-public (whitelist-user (user-principal principal))
  (begin
    (asserts! (is-eq tx-sender DEPLOYER-PRINCIPAL) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-none (map-get? whitelisted-users user-principal)) ERR-INVALID-USER-ADDRESS)
    (record-event "user-whitelisted" "new user added")
    (ok (map-set whitelisted-users user-principal true))))

(define-public (remove-whitelisted-user (user-principal principal))
  (begin
    (asserts! (is-eq tx-sender DEPLOYER-PRINCIPAL) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-some (map-get? whitelisted-users user-principal)) ERR-USER-NOT-WHITELISTED)
    (record-event "user-removed" "user removed from whitelist")
    (ok (map-delete whitelisted-users user-principal))))

(define-public (batch-whitelist-users (user-addresses (list 200 principal)))
  (begin
    (asserts! (is-eq tx-sender DEPLOYER-PRINCIPAL) ERR-UNAUTHORIZED-ACCESS)
    (record-event "batch-whitelist" "multiple users added")
    (ok (map whitelist-user user-addresses))))

(define-public (set-reward-amount (updated-amount uint))
  (begin
    (asserts! (is-eq tx-sender DEPLOYER-PRINCIPAL) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> updated-amount u0) ERR-INVALID-REWARD-AMOUNT)
    (var-set reward-per-user updated-amount)
    (record-event "reward-updated" "reward amount modified")
    (ok updated-amount)))

(define-public (set-withdrawal-period (updated-period uint))
  (begin
    (asserts! (is-eq tx-sender DEPLOYER-PRINCIPAL) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> updated-period u0) ERR-INVALID-TIME-PERIOD)
    (var-set withdrawal-time-limit updated-period)
    (record-event "period-modified" "withdrawal period updated")
    (ok updated-period)))

;; Token giveaway distribution function

(define-public (collect-reward-tokens)
  (let (
    (user-principal tx-sender)
    (reward-amount (var-get reward-per-user))
  )
    (asserts! (var-get giveaway-status-active) ERR-GIVEAWAY-SUSPENDED)
    (asserts! (is-some (map-get? whitelisted-users user-principal)) ERR-USER-NOT-WHITELISTED)
    (asserts! (is-none (map-get? collected-rewards user-principal)) ERR-REWARD-ALREADY-COLLECTED)
    (asserts! (<= reward-amount (ft-get-balance token-giveaway-distribution DEPLOYER-PRINCIPAL)) ERR-INSUFFICIENT-CONTRACT-FUNDS)
    (try! (ft-transfer? token-giveaway-distribution reward-amount DEPLOYER-PRINCIPAL user-principal))
    (map-set collected-rewards user-principal reward-amount)
    (var-set tokens-already-distributed (+ (var-get tokens-already-distributed) reward-amount))
    (record-event "reward-collected" "user claimed tokens")
    (ok reward-amount)))

;; Token withdrawal function

(define-public (withdraw-unused-tokens)
  (let (
    (current-block block-height)
    (withdrawal-allowed-after (+ (var-get giveaway-launch-block) (var-get withdrawal-time-limit)))
  )
    (asserts! (is-eq tx-sender DEPLOYER-PRINCIPAL) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (>= current-block withdrawal-allowed-after) ERR-WITHDRAWAL-PERIOD-ACTIVE)
    (let (
      (total-supply (ft-get-supply token-giveaway-distribution))
      (total-distributed (var-get tokens-already-distributed))
      (unused-tokens (- total-supply total-distributed))
    )
      (try! (ft-burn? token-giveaway-distribution unused-tokens DEPLOYER-PRINCIPAL))
      (record-event "tokens-withdrawn" "unused tokens burned")
      (ok unused-tokens))))

;; Read-only functions

(define-read-only (get-giveaway-status)
  (var-get giveaway-status-active))

(define-read-only (check-user-whitelist-status (user-principal principal))
  (default-to false (map-get? whitelisted-users user-principal)))

(define-read-only (check-user-reward-status (user-principal principal))
  (is-some (map-get? collected-rewards user-principal)))

(define-read-only (get-user-collected-amount (user-principal principal))
  (default-to u0 (map-get? collected-rewards user-principal)))

(define-read-only (get-total-distributed-tokens)
  (var-get tokens-already-distributed))

(define-read-only (get-reward-per-user)
  (var-get reward-per-user))

(define-read-only (get-withdrawal-period)
  (var-get withdrawal-time-limit))

(define-read-only (get-giveaway-start-block)
  (var-get giveaway-launch-block))

(define-read-only (get-logged-event (event-id uint))
  (map-get? event-log event-id))

;; Contract initialization

(begin
  (ft-mint? token-giveaway-distribution u1000000000 DEPLOYER-PRINCIPAL))