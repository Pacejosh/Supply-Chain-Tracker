;; Supply Chain Tracker: Decentralized product traceability and authenticity verification
;; Manufacturers can register products, distributors can update status, and inspectors can verify quality

(define-data-var chief-inspector principal tx-sender)

(define-map product-registry
  { product-id: uint }
  {
    manufacturer: principal,
    batch-cost: uint,
    product-name: (string-ascii 50),
    origin-details: (string-ascii 500),
    production-date: uint,
    certified: bool
  })

(define-map tracking-records
  { product-id: uint, record-id: uint }
  {
    handler: principal,
    timestamp: uint,
    status: (string-ascii 20)
  })

(define-data-var next-product-id uint u1)

(define-map record-counter
  { product-id: uint }
  { records: uint })

;; Register new product in supply chain
(define-public (register-product (name-input (string-ascii 50)) (origin-input (string-ascii 500)) (date-input uint) (cost-input uint))
  (let
    (
      (product-id (var-get next-product-id))
      (record-id u0)
      (name name-input)
      (origin origin-input)
      (date date-input)
      (cost cost-input)
    )
    ;; Input validation
    (asserts! (> cost u0) (err u1))
    (asserts! (> (len name) u0) (err u5))
    (asserts! (> (len origin) u0) (err u6))
    (asserts! (> date u0) (err u7))
    
    (map-set product-registry
      { product-id: product-id }
      {
        manufacturer: tx-sender,
        batch-cost: cost,
        product-name: name,
        origin-details: origin,
        production-date: date,
        certified: false
      })
    
    (map-set tracking-records
      { product-id: product-id, record-id: record-id }
      {
        handler: tx-sender,
        timestamp: product-id,
        status: "manufactured"
      })
    
    (map-set record-counter
      { product-id: product-id }
      { records: u1 })
    
    (var-set next-product-id (+ product-id u1))
    (ok product-id)
  ))

;; Update product status in supply chain
(define-public (update-status (product-id-input uint))
  (let
    (
      (product-id product-id-input)
      (product-info (unwrap! (map-get? product-registry { product-id: product-id }) (err u2)))
      (cost (get batch-cost product-info))
      (manufacturer (get manufacturer product-info))
      (record-data (default-to { records: u0 } (map-get? record-counter { product-id: product-id })))
      (record-id (get records record-data))
      (new-record-id (+ record-id u1))
    )
    ;; Input validation
    (asserts! (> product-id u0) (err u8))
    (asserts! (not (is-eq tx-sender manufacturer)) (err u3))
    
    (try! (stx-transfer? cost tx-sender manufacturer))
    
    (map-set tracking-records
      { product-id: product-id, record-id: record-id }
      {
        handler: tx-sender,
        timestamp: (var-get next-product-id),
        status: "distributed"
      })
    
    (map-set record-counter
      { product-id: product-id }
      { records: new-record-id })
    
    (ok true)
  ))

;; Certify product quality (chief inspector only)
(define-public (certify-product (product-id-input uint))
  (let
    (
      (product-id product-id-input)
      (product-info (unwrap! (map-get? product-registry { product-id: product-id }) (err u2)))
      (record-data (default-to { records: u0 } (map-get? record-counter { product-id: product-id })))
      (record-id (get records record-data))
      (new-record-id (+ record-id u1))
    )
    ;; Input validation
    (asserts! (> product-id u0) (err u8))
    (asserts! (is-eq tx-sender (var-get chief-inspector)) (err u4))
    
    (map-set product-registry
      { product-id: product-id }
      (merge product-info { certified: true }))
    
    (map-set tracking-records
      { product-id: product-id, record-id: record-id }
      {
        handler: (get manufacturer product-info),
        timestamp: (var-get next-product-id),
        status: "certified"
      })
    
    (map-set record-counter
      { product-id: product-id }
      { records: new-record-id })
    
    (ok true)
  ))

;; Get product details
(define-read-only (get-product (product-id uint))
  (map-get? product-registry { product-id: product-id }))

;; Get tracking record entry
(define-read-only (get-tracking-record (product-id uint) (record-id uint))
  (map-get? tracking-records { product-id: product-id, record-id: record-id }))

;; Get total tracking records for a product
(define-read-only (get-record-count (product-id uint))
  (let
    (
      (record-data (default-to { records: u0 } (map-get? record-counter { product-id: product-id })))
    )
    (get records record-data)
  ))
