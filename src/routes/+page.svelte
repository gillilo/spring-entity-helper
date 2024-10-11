<script>
	import { onMount } from 'svelte';
	import Prism from 'prismjs';
  import 'prismjs/themes/prism.css';
  import 'prismjs/components/prism-java.min';
  import 'prismjs/components/prism-kotlin.min';
  import 'prismjs/components/prism-sql.min';

  let sqlCode = `
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
`;

  let entityCode = ``;
  let repositoryCode = ``;
  let serviceCode = ``;
  let controllerCode = ``;

  let codeElements = {};

	let entityName = '';
	let packageName = 'com.example.demo';

	function generateSpringBootClasses(sql, packageName) {
    // Helper functions to map SQL types to Java types
    const typeMapping = {
        'BIGINT': 'Long',
        'VARCHAR': 'String',
        'BOOLEAN': 'Boolean',
        'INT': 'Integer',
        'TEXT': 'String',
        'TINYINT': 'Integer',
        'SMALLINT': 'Integer',
        'MEDIUMINT': 'Integer',
        'FLOAT': 'Float',
        'DOUBLE': 'Double',
        'DECIMAL': 'BigDecimal',
        'DATE': 'LocalDate',
        'TIME': 'LocalTime',
        'DATETIME': 'LocalDateTime',
        'TIMESTAMP': 'Instant',
        'CHAR': 'String',
        'TINYTEXT': 'String',
        'MEDIUMTEXT': 'String',
        'LONGTEXT': 'String',
        'BLOB': 'byte[]',
        'JSON': 'String',
        'ENUM': 'String',
        'SET': 'Set<String>',
    };

    // Parse table name and columns from SQL
    const tableNameRegex = /CREATE TABLE (\w+)/i;
    const columnRegex = /(\w+)\s+(\w+)(\(\d+\))?.*(NOT NULL)?(UNIQUE)?/g;
    const primaryKeyRegex = /PRIMARY KEY\s*\((\w+)\)/i;  // Capture primary key

    const tableNameMatch = sql.match(tableNameRegex);
    if (!tableNameMatch) {
        throw new Error("유효하지 않은 SQL: 테이블 이름을 찾을 수 없습니다.");
    }

    const tableName = tableNameMatch[1];
    entityName = tableName.charAt(0).toUpperCase() + tableName.slice(1);

    let primaryKey = null;
    const primaryKeyMatch = sql.match(primaryKeyRegex);
    if (primaryKeyMatch) {
        primaryKey = primaryKeyMatch[1];
    }

    let columns = [];
    let match;
    while ((match = columnRegex.exec(sql)) !== null) {
        if (match[1].toLowerCase() !== 'create') {  // 'CREATE' 키워드 제외
            columns.push({
                name: match[1],
                type: typeMapping[match[2]] || 'String', // Default to String if type is unknown
                notNull: !!match[4],
                unique: !!match[5]
            });
        }
    }

    // Generate Entity class
    let entityClass = `
package ${packageName};

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter
@Setter
@NoArgsConstructor
@Table(name = "${tableName}")
public class ${entityName} {\n`;

    columns.forEach(col => {
        if (col.name === primaryKey) {
            entityClass += `
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private ${col.type} ${col.name};\n`;
        } else {
            entityClass += `
    @Column(name = "${col.name}"`;
            if (col.notNull) entityClass += ', nullable = false';
            if (col.unique) entityClass += ', unique = true';
            entityClass += `)\n    private ${col.type} ${col.name};\n`;
        }
    });

    entityClass += `}\n`;

    // Generate Repository interface
    let repositoryClass = `
package ${packageName};

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ${entityName}Repository extends JpaRepository<${entityName}, ${primaryKey ? typeMapping[columns.find(col => col.name === primaryKey).type] : 'Long'}> {
}
`;

    // Generate Service class
    let serviceClass = `
package ${packageName};

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class ${entityName}Service {

    @Autowired
    private ${entityName}Repository ${tableName}Repository;

    public List<${entityName}> getAll${entityName}s() {
        return ${tableName}Repository.findAll();
    }

    public Optional<${entityName}> get${entityName}ById(${primaryKey ? typeMapping[columns.find(col => col.name === primaryKey).type] : 'Long'} id) {
        return ${tableName}Repository.findById(id);
    }

    public ${entityName} create${entityName}(${entityName} ${tableName}) {
        return ${tableName}Repository.save(${tableName});
    }

    public ${entityName} update${entityName}(Long id, ${entityName} ${tableName}Details) {
        ${entityName} ${tableName} = ${tableName}Repository.findById(id)
            .orElseThrow(() -> new RuntimeException("${entityName} not found with id: " + id));
        
        // Update fields here, for example:
        // ${tableName}.setUsername(${tableName}Details.getUsername());

        return ${tableName}Repository.save(${tableName});
    }

    public void delete${entityName}(Long id) {
        ${tableName}Repository.deleteById(id);
    }
}
`;

    // Generate Controller class
    let controllerClass = `
package ${packageName};

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/${tableName}s")
public class ${entityName}Controller {

    @Autowired
    private ${entityName}Service ${tableName}Service;

    @GetMapping
    public List<${entityName}> getAll${entityName}s() {
        return ${tableName}Service.getAll${entityName}s();
    }

    @GetMapping("/{id}")
    public ResponseEntity<${entityName}> get${entityName}ById(@PathVariable ${primaryKey ? typeMapping[columns.find(col => col.name === primaryKey).type] : 'Long'} id) {
        Optional<${entityName}> ${tableName} = ${tableName}Service.get${entityName}ById(id);
        return ${tableName}.map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PostMapping
    public ${entityName} create${entityName}(@RequestBody ${entityName} ${tableName}) {
        return ${tableName}Service.create${entityName}(${tableName});
    }

    @PutMapping("/{id}")
    public ResponseEntity<${entityName}> update${entityName}(@PathVariable Long id, @RequestBody ${entityName} ${tableName}Details) {
        return ResponseEntity.ok(${tableName}Service.update${entityName}(id, ${tableName}Details));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete${entityName}(@PathVariable Long id) {
        ${tableName}Service.delete${entityName}(id);
        return ResponseEntity.noContent().build();
    }
}
`;
    return {
        entityClass,
        repositoryClass,
        serviceClass,
        controllerClass
    };
	}

	function generateCode() {
		try {
			const result = generateSpringBootClasses(sqlCode, packageName);
			entityCode = result.entityClass;
			repositoryCode = result.repositoryClass;
			serviceCode = result.serviceClass;
			controllerCode = result.controllerClass;
			Prism.highlightAll();
			
			// 코드 블록 내용 업데이트
			if (codeElements.entity) codeElements.entity.textContent = entityCode;
			if (codeElements.repository) codeElements.repository.textContent = repositoryCode;
			if (codeElements.service) codeElements.service.textContent = serviceCode;
			if (codeElements.controller) codeElements.controller.textContent = controllerCode;
			
			// 하이라이팅 다시 적용
			Prism.highlightElement(codeElements.entity);
			Prism.highlightElement(codeElements.repository);
			Prism.highlightElement(codeElements.service);
			Prism.highlightElement(codeElements.controller);
		} catch (error) {
			console.error('코드 생성 중 오류 발생:', error);
			alert('SQL 구문을 확인해 주세요: ' + error.message);
		}
	}

	function downloadCode() {
		const files = [
			{ name: `${entityName}.java`, content: entityCode },
			{ name: `${entityName}Repository.java`, content: repositoryCode },
			{ name: `${entityName}Service.java`, content: serviceCode },
			{ name: `${entityName}Controller.java`, content: controllerCode }
		];

		files.forEach(file => {
			const blob = new Blob([file.content], { type: 'text/plain' });
			const link = document.createElement('a');
			link.href = URL.createObjectURL(blob);
			link.download = file.name;
			link.click();
			URL.revokeObjectURL(link.href);
		});
	}
	
	onMount(() => {
		generateCode();
	});
</script>

<div class="grid grid-cols-1 md:grid-cols-1 gap-4 p-2">
	<div class="bg-gray-100 rounded-lg shadow-md p-3">
		<h2 class="text-xl font-bold mb-2 text-yellow-600">SQL</h2>
		<pre class="language-sql bg-white rounded-md">
			<code bind:this={codeElements.sql} contenteditable="true" class="block overflow-x-auto text-sm" on:input={(e) => sqlCode = e.target.textContent}>
			{sqlCode}
			</code>
		</pre>
	</div>
</div>

<div class="flex items-center justify-between mt-3 p-2">
	<input type="text" placeholder="패키지 이름" bind:value={packageName} class="p-1 border rounded text-black flex-grow mr-2 text-sm" />
	<button class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-1 px-3 rounded mr-2 text-sm" on:click={generateCode}>
		생성
	</button>
	<button class="bg-green-500 hover:bg-green-700 text-white font-bold py-1 px-3 rounded text-sm" on:click={downloadCode}>
		다운로드
	</button>
</div>

<div class="grid grid-cols-1 md:grid-cols-2 gap-4 p-2">
  <div class="bg-gray-100 rounded-lg shadow-md p-3">
    <h2 class="text-xl font-bold mb-2 text-blue-600">Entity</h2>
    <pre class="language-java bg-white rounded-md">
      <code bind:this={codeElements.entity} class="block overflow-x-auto h-60 text-sm"></code>
    </pre>
  </div>

  <div class="bg-gray-100 rounded-lg shadow-md p-3">
    <h2 class="text-xl font-bold mb-2 text-green-600">Repository</h2>
    <pre class="language-java bg-white rounded-md">
      <code bind:this={codeElements.repository} class="block overflow-x-auto h-60 text-sm"></code>
    </pre>
  </div>

  <div class="bg-gray-100 rounded-lg shadow-md p-3">
    <h2 class="text-xl font-bold mb-2 text-purple-600">Service</h2>
    <pre class="language-java bg-white rounded-md">
      <code bind:this={codeElements.service} class="block overflow-x-auto h-60 text-sm"></code>
    </pre>
  </div>

  <div class="bg-gray-100 rounded-lg shadow-md p-3">
    <h2 class="text-xl font-bold mb-2 text-red-600">Controller</h2>
    <pre class="language-java bg-white rounded-md">
      <code bind:this={codeElements.controller} class="block overflow-x-auto h-60 text-sm"></code>
    </pre>
  </div>
</div>

<style>
  pre code:focus {
    outline: none;
  }
  pre code {
    font-size: 0.9em;
  }
</style>