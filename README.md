# Spring Boot 클래스 생성기

이 프로젝트는 SQL CREATE 문을 입력받아 Spring Boot 애플리케이션을 위한 JPA Entity, Repository, Service, Controller 클래스를 자동으로 생성합니다.

## 사용 방법

1. SQL CREATE 문을 입력합니다.
2. 패키지 이름을 입력합니다.
3. 생성 버튼을 클릭합니다.
4. 생성된 코드를 확인하고 복사하여 사용합니다.

## 생성되는 클래스

- Entity: JPA 엔티티 클래스
- Repository: Spring Data JPA 리포지토리 인터페이스
- Service: 비즈니스 로직을 처리하는 서비스 클래스
- Controller: REST API 엔드포인트를 제공하는 컨트롤러 클래스

## 주의사항

- 생성된 코드는 기본적인 구조를 제공하는 템플릿입니다. 실제 프로젝트에 적용할 때는 필요에 따라 수정이 필요할 수 있습니다.
- 복잡한 관계나 특수한 데이터 타입은 수동으로 처리해야 할 수 있습니다.
- 생성된 코드를 사용하기 전에 반드시 검토하고 테스트해야 합니다.

## 예시
```sql
CREATE TABLE user (
	id BIGINT AUTO_INCREMENT PRIMARY KEY,
	username VARCHAR(255) NOT NULL UNIQUE,
	password VARCHAR(255) NOT NULL,
	email VARCHAR(255) NOT NULL UNIQUE,
	first_name VARCHAR(255) NOT NULL,
	last_name VARCHAR(255) NOT NULL,
	phone_number VARCHAR(20),
	address VARCHAR(255),
	enabled BOOLEAN NOT NULL DEFAULT TRUE,
	role VARCHAR(50)
);
```