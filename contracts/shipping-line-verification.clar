;; Shipping Line Verification Contract
;; This contract validates shipping companies and maintains their verification status

;; Define data maps
(define-map shipping-lines
  { company-id: (string-ascii 32) }
  {
    name: (string-ascii 100),
    verified: bool,
    verification-date: uint,
    verification-authority: (string-ascii 100)
  }
)

;; Define data variables
(define-data-var admin principal tx-sender)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-ALREADY-VERIFIED u101)
(define-constant ERR-NOT-FOUND u102)

;; Read-only functions
(define-read-only (get-shipping-line (company-id (string-ascii 32)))
  (map-get? shipping-lines { company-id: company-id })
)

(define-read-only (is-verified (company-id (string-ascii 32)))
  (default-to false (get verified (get-shipping-line company-id)))
)

;; Public functions
(define-public (register-shipping-line
    (company-id (string-ascii 32))
    (name (string-ascii 100))
    (verification-authority (string-ascii 100)))
  (begin
    (asserts! (is-admin tx-sender) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-none (get-shipping-line company-id)) (err ERR-ALREADY-VERIFIED))
    (ok (map-set shipping-lines
      { company-id: company-id }
      {
        name: name,
        verified: false,
        verification-date: u0,
        verification-authority: verification-authority
      }
    ))
  )
)

(define-public (verify-shipping-line (company-id (string-ascii 32)))
  (let ((shipping-line (get-shipping-line company-id)))
    (begin
      (asserts! (is-admin tx-sender) (err ERR-NOT-AUTHORIZED))
      (asserts! (is-some shipping-line) (err ERR-NOT-FOUND))
      (ok (map-set shipping-lines
        { company-id: company-id }
        (merge (unwrap-panic shipping-line)
          {
            verified: true,
            verification-date: block-height
          }
        )
      ))
    )
  )
)

(define-public (revoke-verification (company-id (string-ascii 32)))
  (let ((shipping-line (get-shipping-line company-id)))
    (begin
      (asserts! (is-admin tx-sender) (err ERR-NOT-AUTHORIZED))
      (asserts! (is-some shipping-line) (err ERR-NOT-FOUND))
      (ok (map-set shipping-lines
        { company-id: company-id }
        (merge (unwrap-panic shipping-line)
          { verified: false }
        )
      ))
    )
  )
)

;; Private functions
(define-private (is-admin (caller principal))
  (is-eq caller (var-get admin))
)

;; Admin functions
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin tx-sender) (err ERR-NOT-AUTHORIZED))
    (ok (var-set admin new-admin))
  )
)
