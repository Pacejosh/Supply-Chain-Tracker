# Supply Chain Tracker

A transparent product journey tracking system built on Stacks blockchain.

## Features

- **Product Registration**: Manufacturers can register products with batch details
- **Shipment Tracking**: Real-time updates throughout the supply chain
- **Authentication**: Auditor verification for product authenticity
- **Complete Traceability**: Full product journey from manufacture to delivery

## Smart Contract Functions

### Public Functions
- `register-product`: Register new product in supply chain
- `update-shipment`: Update product location and status
- `authenticate-product`: Verify product authenticity (auditor only)

### Read-Only Functions
- `get-product`: Retrieve product information
- `get-shipment-log`: Access shipment history
- `get-shipment-count`: Get total shipment updates

## Usage

Deploy the contract to enable supply chain transparency. Manufacturers register products, distributors update shipment status, and auditors verify authenticity.

## License

MIT
```

**PR Title**: feat: implement supply chain tracking smart contract

**PR Description**: 
Introduces a comprehensive supply chain tracking system with product registration, shipment updates, and auditor authentication. Features complete traceability from manufacturer to end consumer with blockchain-verified authenticity and transparent fee structure.

**README Commit**: docs: add supply chain tracker documentation and API guide

**Code Commit**: feat: implement product tracking with shipment management system

**Branch Name**: feature/supply-chain-tracker

---

## PROJECT 4: SKILL CERTIFICATION PLATFORM

<CodeProject id="art-marketplace">

```clarity file="contracts/skill-certification-platform.clar"
;; Skill Certification Platform: Decentralized professional certification system
;; Instructors can create courses, students can enroll, and validators can issue certificates

(define-data-var certification-authority principal tx-sender)

(define-map course-catalog
  { course-id: uint }
  {
    instructor: principal,
    enrollment-fee: uint,
    course-title: (string-ascii 50),
    course-curriculum: (string-ascii 500),
    duration-weeks: uint,
    certified: bool
  })

(define-map enrollment-records
  { course-id: uint, enrollment-id: uint }
  {
    student: principal,
    enrollment-date: uint,
    completion-status: (string-ascii 20)
  })

(define-data-var next-course-id uint u1)

(define-map enrollment-counter
  { course-id: uint }
  { enrollments: uint })

;; Create new certification course
(define-public (create-course (title-input (string-ascii 50)) (curriculum-input (string-ascii 500)) (duration-input uint) (fee-input uint))
  (let
    (
      (course-id (var-get next-course-id))
      (enrollment-id u0)
      (title title-input)
      (curriculum curriculum-input)
      (duration duration-input)
      (fee fee-input)
    )
    ;; Input validation
    (asserts! (> fee u0) (err u1))
    (asserts! (> (len title) u0) (err u5))
    (asserts! (> (len curriculum) u0) (err u6))
    (asserts! (> duration u0) (err u7))
    
    (map-set course-catalog
      { course-id: course-id }
      {
        instructor: tx-sender,
        enrollment-fee: fee,
        course-title: title,
        course-curriculum: curriculum,
        duration-weeks: duration,
        certified: false
      })
    
    (map-set enrollment-records
      { course-id: course-id, enrollment-id: enrollment-id }
      {
        student: tx-sender,
        enrollment-date: course-id,
        completion-status: "created"
      })
    
    (map-set enrollment-counter
      { course-id: course-id }
      { enrollments: u1 })
    
    (var-set next-course-id (+ course-id u1))
    (ok course-id)
  ))

;; Enroll in certification course
(define-public (enroll-course (course-id-input uint))
  (let
    (
      (course-id course-id-input)
      (course-info (unwrap! (map-get? course-catalog { course-id: course-id }) (err u2)))
      (fee (get enrollment-fee course-info))
      (instructor (get instructor course-info))
      (enrollment-data (default-to { enrollments: u0 } (map-get? enrollment-counter { course-id: course-id })))
      (enrollment-id (get enrollments enrollment-data))
      (new-enrollment-id (+ enrollment-id u1))
    )
    ;; Input validation
    (asserts! (> course-id u0) (err u8))
    (asserts! (not (is-eq tx-sender instructor)) (err u3))
    
    (try! (stx-transfer? fee tx-sender instructor))
    
    (map-set enrollment-records
      { course-id: course-id, enrollment-id: enrollment-id }
      {
        student: tx-sender,
        enrollment-date: (var-get next-course-id),
        completion-status: "enrolled"
      })
    
    (map-set enrollment-counter
      { course-id: course-id }
      { enrollments: new-enrollment-id })
    
    (ok true)
  ))

;; Issue certification (certification authority only)
(define-public (issue-certification (course-id-input uint))
  (let
    (
      (course-id course-id-input)
      (course-info (unwrap! (map-get? course-catalog { course-id: course-id }) (err u2)))
      (enrollment-data (default-to { enrollments: u0 } (map-get? enrollment-counter { course-id: course-id })))
      (enrollment-id (get enrollments enrollment-data))
      (new-enrollment-id (+ enrollment-id u1))
    )
    ;; Input validation
    (asserts! (> course-id u0) (err u8))
    (asserts! (is-eq tx-sender (var-get certification-authority)) (err u4))
    
    (map-set course-catalog
      { course-id: course-id }
      (merge course-info { certified: true }))
    
    (map-set enrollment-records
      { course-id: course-id, enrollment-id: enrollment-id }
      {
        student: (get instructor course-info),
        enrollment-date: (var-get next-course-id),
        completion-status: "certified"
      })
    
    (map-set enrollment-counter
      { course-id: course-id }
      { enrollments: new-enrollment-id })
    
    (ok true)
  ))

;; Get course details
(define-read-only (get-course (course-id uint))
  (map-get? course-catalog { course-id: course-id }))

;; Get enrollment record entry
(define-read-only (get-enrollment-record (course-id uint) (enrollment-id uint))
  (map-get? enrollment-records { course-id: course-id, enrollment-id: enrollment-id }))

;; Get total enrollments for course
(define-read-only (get-enrollment-count (course-id uint))
  (let
    (
      (enrollment-data (default-to { enrollments: u0 } (map-get? enrollment-counter { course-id: course-id })))
    )
    (get enrollments enrollment-data)
  ))