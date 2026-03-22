(define-trait ft-trait
  (
    (transfer (uint principal principal) (response bool uint))
    (balance-of (principal) (response uint uint))
    (total-supply () (response uint uint))
    (decimals () (response uint uint))
    (name () (response (string-ascii 32) uint))
    (symbol () (response (string-ascii 32) uint))
  )
)

(define-constant ERR-NOT-FOUND u100)
(define-constant ERR-INSUFFICIENT-FUNDS u101)
(define-constant ERR-UNAUTHORIZED u103)
(define-constant ERR-NOT-FREELANCER u104)
(define-constant ERR-ALREADY-VOTED u105)
(define-constant ERR-AUCTION-NOT-FOUND u106)
(define-constant ERR-BID-TOO-LOW u107)
(define-constant ERR-AUCTION-ENDED u108)
(define-constant ERR-INVALID-SCORE u109)
(define-constant ERR-INVALID-AMOUNT u110)

(define-constant DAO-QUORUM u3)
(define-constant MIN-STAKING-AMOUNT u50000)

(define-data-var job-id-counter uint u0)
(define-map reputation principal uint)
(define-map staked principal uint)
(define-map subscribers principal bool)
(define-map job-auctions uint { min-bid: uint, highest-bidder: (optional principal), end-block: uint })
(define-map votes uint (list 10 principal))

(define-map jobs
  uint
  {
    client: principal,
    freelancer: (optional principal),
    amount: uint,
    milestone: uint,
    paid: bool,
    approved: bool
  }
)

;; ====================
;; == CORE FUNCTIONS ==
;; ====================

(define-public (subscribe)
  (begin
    (map-set subscribers tx-sender true)
    (ok true)
  )
)

(define-public (stake)
  (let ((amount (stx-get-balance tx-sender)))
    (if (< amount MIN-STAKING-AMOUNT)
      (err ERR-INSUFFICIENT-FUNDS)
      (begin
        (try! (stx-transfer? MIN-STAKING-AMOUNT tx-sender (as-contract tx-sender)))
        (map-set staked tx-sender MIN-STAKING-AMOUNT)
        (ok true)
      )
    )
  )
)

(define-public (post-job (amount uint))
  (begin
    (asserts! (> amount u0) (err ERR-INVALID-AMOUNT))
    (let ((id (+ (var-get job-id-counter) u1)))
      (begin
        (var-set job-id-counter id)
        (map-set jobs id {
          client: tx-sender,
          freelancer: none,
          amount: amount,
          milestone: u0,
          paid: false,
          approved: false
        })
        (ok id)
      )
    )
  )
)

(define-public (bid-job (job-id uint))
  (let ((job (map-get? jobs job-id)))
    (match job job-data
      (begin
        (asserts! (is-none (get freelancer job-data)) (err ERR-UNAUTHORIZED))
        (map-set jobs job-id (merge job-data { freelancer: (some tx-sender) }))
        (ok true)
      )
      (err ERR-NOT-FOUND)
    )
  )
)

(define-public (deposit-escrow (job-id uint))
  (let ((job (map-get? jobs job-id)))
    (match job job-data
      (if (is-eq tx-sender (get client job-data))
        (begin
          (try! (stx-transfer? (get amount job-data) tx-sender (as-contract tx-sender)))
          (ok true)
        )
        (err ERR-UNAUTHORIZED)
      )
      (err ERR-NOT-FOUND)
    )
  )
)

(define-public (submit-milestone (job-id uint))
  (let ((job (map-get? jobs job-id)))
    (match job job-data
      (let ((current-freelancer (get freelancer job-data))
            (current-milestone (get milestone job-data)))
        (asserts! (is-eq tx-sender (unwrap-panic current-freelancer)) (err ERR-NOT-FREELANCER))
        (map-set jobs job-id (merge job-data { milestone: (+ current-milestone u1) }))
        (ok true))
      (err ERR-NOT-FOUND)
    )
  )
)

(define-public (vote-approve (job-id uint))
  (let ((job (map-get? jobs job-id)))
    (match job job-data
      (begin
        (let ((current-votes (default-to (list ) (map-get? votes job-id))))
          (asserts! (not (is-some (index-of? current-votes tx-sender))) (err ERR-ALREADY-VOTED))
          (let ((new-votes (unwrap-panic (as-max-len? (append current-votes tx-sender) u10))))
            (begin
              (map-set votes job-id new-votes)
              (if (>= (len new-votes) DAO-QUORUM)
                (begin
                  (try! (stx-transfer? (get amount job-data) (as-contract tx-sender) (unwrap-panic (get freelancer job-data))))
                  (map-set jobs job-id (merge job-data { paid: true, approved: true }))
                  (ok true)
                )
                (ok false)
              )
            )
          )
        )
      )
      (err ERR-NOT-FOUND)
    )
  )
)

(define-public (reputation-score (user principal))
  (ok (default-to u0 (map-get? reputation user)))
)

(define-public (rate-freelancer (freelancer principal) (score uint))
  (begin
    (asserts! (and (>= score u0) (<= score u5)) (err ERR-INVALID-SCORE))
    (let ((rep (default-to u0 (map-get? reputation freelancer))))
      (map-insert reputation freelancer (+ rep score))
      (ok true)
    )
  )
)

(define-public (create-job-auction (job-id uint) (initial-bid uint) (auction-end uint))
  (begin
    (asserts! (> initial-bid u0) (err ERR-INVALID-AMOUNT))
    (asserts! (> auction-end u0) (err ERR-INVALID-AMOUNT))
    (ok (map-insert job-auctions 
      job-id 
      { min-bid: initial-bid, highest-bidder: none, end-block: auction-end }))
  )
)

(define-public (place-bid (job-id uint) (bid-amount uint))
  (let ((auction (unwrap! (map-get? job-auctions job-id) (err ERR-AUCTION-NOT-FOUND))))
    (let ((current-min-bid (get min-bid auction)))
      (asserts! (> bid-amount u0) (err ERR-INVALID-AMOUNT))
      (asserts! (>= bid-amount current-min-bid) (err ERR-BID-TOO-LOW))
      (ok (map-insert job-auctions 
        job-id 
        { min-bid: bid-amount, highest-bidder: (some tx-sender), end-block: (get end-block auction) }))
    )
  )
)

(define-read-only (get-job (job-id uint))
  (let ((job (map-get? jobs job-id)))
    (match job job-data
      (ok job-data)
      (err ERR-NOT-FOUND)
    )
  )
)

(define-read-only (get-auction (job-id uint))
  (let ((auction (map-get? job-auctions job-id)))
    (match auction auction-data
      (ok auction-data)
      (err ERR-AUCTION-NOT-FOUND)
    )
  )
)
