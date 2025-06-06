;; Container Tracking Contract
;; This contract tracks shipping containers globally

;; Define data maps
(define-map containers
  { container-id: (string-ascii 20) }
  {
    owner: principal,
    current-location: (string-ascii 100),
    status: (string-ascii 20),
    last-updated: uint,
    shipping-line: (string-ascii 32)
  }
)

(define-map container-history
  { container-id: (string-ascii 20), timestamp: uint }
  {
    location: (string-ascii 100),
    status: (string-ascii 20),
    handler: principal
  }
)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-CONTAINER-NOT-FOUND u101)
(define-constant ERR-CONTAINER-EXISTS u102)

;; Read-only functions
(define-read-only (get-container (container-id (string-ascii 20)))
  (map-get? containers { container-id: container-id })
)

(define-read-only (get-container-location (container-id (string-ascii 20)))
  (get current-location (default-to
    {
      owner: tx-sender,
      current-location: "UNKNOWN",
      status: "UNKNOWN",
      last-updated: u0,
      shipping-line: ""
    }
    (get-container container-id)))
)

;; Public functions
(define-public (register-container
    (container-id (string-ascii 20))
    (shipping-line (string-ascii 32)))
  (begin
    (asserts! (is-none (get-container container-id)) (err ERR-CONTAINER-EXISTS))
    (ok (map-set containers
      { container-id: container-id }
      {
        owner: tx-sender,
        current-location: "REGISTERED",
        status: "IDLE",
        last-updated: block-height,
        shipping-line: shipping-line
      }
    ))
  )
)

(define-public (update-container-location
    (container-id (string-ascii 20))
    (new-location (string-ascii 100))
    (new-status (string-ascii 20)))
  (let ((container (get-container container-id)))
    (begin
      (asserts! (is-some container) (err ERR-CONTAINER-NOT-FOUND))
      (asserts! (is-authorized-handler tx-sender container-id) (err ERR-NOT-AUTHORIZED))

      ;; Update container history
      (map-set container-history
        { container-id: container-id, timestamp: block-height }
        {
          location: new-location,
          status: new-status,
          handler: tx-sender
        }
      )

      ;; Update current container state
      (ok (map-set containers
        { container-id: container-id }
        (merge (unwrap-panic container)
          {
            current-location: new-location,
            status: new-status,
            last-updated: block-height
          }
        )
      ))
    )
  )
)

;; Private functions
(define-private (is-authorized-handler (handler principal) (container-id (string-ascii 20)))
  (let ((container (get-container container-id)))
    (or
      (is-eq handler (get owner (unwrap-panic container)))
      (is-eq handler tx-sender) ;; For demo purposes, allowing tx-sender
    )
  )
)
