;; REC Retirement Tracking Contract
;; Records permanent retirement of RECs for carbon offsetting

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-INVALID-AMOUNT (err u401))
(define-constant ERR-REC-NOT-FOUND (err u402))
(define-constant ERR-ALREADY-RETIRED (err u403))
(define-constant ERR-INVALID-REASON (err u404))
(define-constant ERR-INSUFFICIENT-AMOUNT (err u405))

;; Data Variables
(define-data-var next-retirement-id uint u1)
(define-data-var total-retired uint u0)

;; Data Maps
(define-map retirements
  { retirement-id: uint }
  {
    rec-id: uint,
    retiree: principal,
    amount: uint,
    reason: (string-ascii 100),
    beneficiary: (optional (string-ascii 100)),
    retirement-date: uint,
    carbon-offset: uint
  }
)

(define-map rec-retirement-status
  { rec-id: uint }
  {
    total-retired: uint,
    active: bool
  }
)

(define-map user-retirements
  { user: principal, retirement-id: uint }
  { active: bool }
)

(define-map retirement-certificates
  { retirement-id: uint }
  {
    certificate-hash: (buff 32),
    issued: bool
  }
)

(define-map carbon-offset-claims
  { user: principal }
  { total-offset: uint }
)

;; Public Functions

;; Retire REC for carbon offsetting
(define-public (retire-rec (rec-id uint) (amount uint) (reason (string-ascii 100)) (beneficiary (optional (string-ascii 100))) (carbon-offset uint))
  (let ((retirement-id (var-get next-retirement-id)))
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (> carbon-offset u0) ERR-INVALID-AMOUNT)
    (asserts! (> (len reason) u0) ERR-INVALID-REASON)

    ;; Check if REC exists and is active
    (let ((retirement-status (map-get? rec-retirement-status { rec-id: rec-id })))
      (if (is-some retirement-status)
        (asserts! (get active (unwrap-panic retirement-status)) ERR-ALREADY-RETIRED)
        true
      )
    )

    ;; Create retirement record
    (map-set retirements
      { retirement-id: retirement-id }
      {
        rec-id: rec-id,
        retiree: tx-sender,
        amount: amount,
        reason: reason,
        beneficiary: beneficiary,
        retirement-date: block-height,
        carbon-offset: carbon-offset
      }
    )

    ;; Update REC retirement status
    (let ((current-retired (default-to u0 (get total-retired (map-get? rec-retirement-status { rec-id: rec-id })))))
      (map-set rec-retirement-status
        { rec-id: rec-id }
        {
          total-retired: (+ current-retired amount),
          active: false
        }
      )
    )

    ;; Track user retirements
    (map-set user-retirements
      { user: tx-sender, retirement-id: retirement-id }
      { active: true }
    )

    ;; Update carbon offset claims
    (let ((current-offset (default-to u0 (get total-offset (map-get? carbon-offset-claims { user: tx-sender })))))
      (map-set carbon-offset-claims
        { user: tx-sender }
        { total-offset: (+ current-offset carbon-offset) }
      )
    )

    ;; Update totals
    (var-set next-retirement-id (+ retirement-id u1))
    (var-set total-retired (+ (var-get total-retired) amount))

    (ok retirement-id)
  )
)

;; Issue retirement certificate
(define-public (issue-certificate (retirement-id uint) (certificate-hash (buff 32)))
  (let ((retirement (map-get? retirements { retirement-id: retirement-id })))
    (asserts! (is-some retirement) ERR-REC-NOT-FOUND)
    (asserts! (is-eq tx-sender (get retiree (unwrap-panic retirement))) ERR-NOT-AUTHORIZED)

    (map-set retirement-certificates
      { retirement-id: retirement-id }
      {
        certificate-hash: certificate-hash,
        issued: true
      }
    )
    (ok true)
  )
)

;; Batch retire RECs
(define-public (batch-retire-recs (retirements-data (list 10 { rec-id: uint, amount: uint, reason: (string-ascii 100), beneficiary: (optional (string-ascii 100)), carbon-offset: uint })))
  (let ((results (map retire-single-rec retirements-data)))
    (ok results)
  )
)

;; Private function for batch processing
(define-private (retire-single-rec (retirement-data { rec-id: uint, amount: uint, reason: (string-ascii 100), beneficiary: (optional (string-ascii 100)), carbon-offset: uint }))
  (retire-rec
    (get rec-id retirement-data)
    (get amount retirement-data)
    (get reason retirement-data)
    (get beneficiary retirement-data)
    (get carbon-offset retirement-data)
  )
)

;; Verify retirement (for auditing)
(define-public (verify-retirement (retirement-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    ;; Additional verification logic can be added here
    (ok true)
  )
)

;; Read-only Functions

(define-read-only (get-retirement (retirement-id uint))
  (map-get? retirements { retirement-id: retirement-id })
)

(define-read-only (get-rec-retirement-status (rec-id uint))
  (map-get? rec-retirement-status { rec-id: rec-id })
)

(define-read-only (get-certificate (retirement-id uint))
  (map-get? retirement-certificates { retirement-id: retirement-id })
)

(define-read-only (get-user-carbon-offset (user principal))
  (map-get? carbon-offset-claims { user: user })
)

(define-read-only (is-rec-retired (rec-id uint))
  (match (map-get? rec-retirement-status { rec-id: rec-id })
    status (not (get active status))
    false
  )
)

(define-read-only (get-total-retired)
  (var-get total-retired)
)

(define-read-only (get-next-retirement-id)
  (var-get next-retirement-id)
)
