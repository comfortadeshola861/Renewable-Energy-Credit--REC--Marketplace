;; REC Issuance Contract
;; Creates digital RECs from verified energy generation

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-INVALID-AMOUNT (err u201))
(define-constant ERR-REC-NOT-FOUND (err u202))
(define-constant ERR-ALREADY-ISSUED (err u203))
(define-constant ERR-NOT-VERIFIED (err u204))
(define-constant ERR-INVALID-GENERATION (err u205))

;; Data Variables
(define-data-var next-rec-id uint u1)
(define-data-var total-recs-issued uint u0)

;; Data Maps
(define-map recs
  { rec-id: uint }
  {
    generation-id: uint,
    facility-id: uint,
    owner: principal,
    energy-source: (string-ascii 10),
    amount: uint,
    issuance-date: uint,
    status: (string-ascii 10)
  }
)

(define-map generation-to-rec
  { generation-id: uint }
  { rec-id: uint }
)

(define-map owner-recs
  { owner: principal, rec-id: uint }
  { active: bool }
)

(define-map owner-balances
  { owner: principal }
  { balance: uint }
)

;; Public Functions

;; Issue REC from verified energy generation
(define-public (issue-rec (generation-id uint) (facility-id uint) (energy-source (string-ascii 10)) (amount uint))
  (let ((rec-id (var-get next-rec-id)))
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (is-none (map-get? generation-to-rec { generation-id: generation-id })) ERR-ALREADY-ISSUED)

    ;; Create REC
    (map-set recs
      { rec-id: rec-id }
      {
        generation-id: generation-id,
        facility-id: facility-id,
        owner: tx-sender,
        energy-source: energy-source,
        amount: amount,
        issuance-date: block-height,
        status: "active"
      }
    )

    ;; Link generation to REC
    (map-set generation-to-rec
      { generation-id: generation-id }
      { rec-id: rec-id }
    )

    ;; Update owner records
    (map-set owner-recs
      { owner: tx-sender, rec-id: rec-id }
      { active: true }
    )

    ;; Update owner balance
    (let ((current-balance (default-to u0 (get balance (map-get? owner-balances { owner: tx-sender })))))
      (map-set owner-balances
        { owner: tx-sender }
        { balance: (+ current-balance amount) }
      )
    )

    ;; Update totals
    (var-set next-rec-id (+ rec-id u1))
    (var-set total-recs-issued (+ (var-get total-recs-issued) u1))

    (ok rec-id)
  )
)

;; Transfer REC ownership
(define-public (transfer-rec (rec-id uint) (new-owner principal))
  (let ((rec (map-get? recs { rec-id: rec-id })))
    (asserts! (is-some rec) ERR-REC-NOT-FOUND)
    (asserts! (is-eq tx-sender (get owner (unwrap-panic rec))) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status (unwrap-panic rec)) "active") ERR-INVALID-GENERATION)

    (let ((rec-data (unwrap-panic rec))
          (amount (get amount (unwrap-panic rec))))

      ;; Update REC owner
      (map-set recs
        { rec-id: rec-id }
        (merge rec-data { owner: new-owner })
      )

      ;; Update old owner records
      (map-delete owner-recs { owner: tx-sender, rec-id: rec-id })
      (let ((old-balance (default-to u0 (get balance (map-get? owner-balances { owner: tx-sender })))))
        (map-set owner-balances
          { owner: tx-sender }
          { balance: (- old-balance amount) }
        )
      )

      ;; Update new owner records
      (map-set owner-recs
        { owner: new-owner, rec-id: rec-id }
        { active: true }
      )
      (let ((new-balance (default-to u0 (get balance (map-get? owner-balances { owner: new-owner })))))
        (map-set owner-balances
          { owner: new-owner }
          { balance: (+ new-balance amount) }
        )
      )

      (ok true)
    )
  )
)

;; Batch issue RECs
(define-public (batch-issue-recs (generations (list 10 { generation-id: uint, facility-id: uint, energy-source: (string-ascii 10), amount: uint })))
  (let ((results (map issue-single-rec generations)))
    (ok results)
  )
)

;; Private function for batch processing
(define-private (issue-single-rec (gen-data { generation-id: uint, facility-id: uint, energy-source: (string-ascii 10), amount: uint }))
  (issue-rec
    (get generation-id gen-data)
    (get facility-id gen-data)
    (get energy-source gen-data)
    (get amount gen-data)
  )
)

;; Read-only Functions

(define-read-only (get-rec (rec-id uint))
  (map-get? recs { rec-id: rec-id })
)

(define-read-only (get-rec-by-generation (generation-id uint))
  (map-get? generation-to-rec { generation-id: generation-id })
)

(define-read-only (get-owner-balance (owner principal))
  (map-get? owner-balances { owner: owner })
)

(define-read-only (is-rec-owner (owner principal) (rec-id uint))
  (is-some (map-get? owner-recs { owner: owner, rec-id: rec-id }))
)

(define-read-only (get-total-recs-issued)
  (var-get total-recs-issued)
)

(define-read-only (get-next-rec-id)
  (var-get next-rec-id)
)
