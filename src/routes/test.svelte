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

	function generateSpringBootClasses(sql) {
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
        throw new Error("Invalid SQL: Table name not found.");
    }

    const tableName = tableNameMatch[1];
    const entityName = tableName.charAt(0).toUpperCase() + tableName.slice(1);

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
package com.example.demo.entity;

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
package com.example.demo.repository;

import com.example.demo.entity.${entityName};
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ${entityName}Repository extends JpaRepository<${entityName}, ${primaryKey ? typeMapping[columns.find(col => col.name === primaryKey).type] : 'Long'}> {
}
`;

    // Generate Service class
    let serviceClass = `
package com.example.demo.service;

import com.example.demo.entity.${entityName};
import com.example.demo.repository.${entityName}Repository;
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
package com.example.demo.controller;

import com.example.demo.entity.${entityName};
import com.example.demo.service.${entityName}Service;
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
        return ${tableName}Service.create${tableName}(${tableName});
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
		const { entityClass, repositoryClass, serviceClass, controllerClass } = generateSpringBootClasses(sqlCode);
		entityCode = entityClass;
		repositoryCode = repositoryClass;
		serviceCode = serviceClass;
		controllerCode = controllerClass;
	}

	onMount(() => {
		generateCode();
	});
</script>

<div class="grid grid-cols-1 md:grid-cols-1 gap-6 p-4">
	<div class="bg-gray-100 rounded-lg shadow-md p-4">
		<h2 class="text-2xl font-bold mb-3 text-yellow-600">SQL</h2>
		<pre class="language-sql bg-white rounded-md">
			<code bind:this={codeElements.sql} contenteditable="true" class="block p-4 overflow-x-auto" on:input={(e) => sqlCode = e.target.textContent}>
			{sqlCode}
			</code>
		</pre>
		<button class="mt-4 bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded" on:click={generateCode}>
			생성
		</button>
	</div>
</div>

<div class="grid grid-cols-1 md:grid-cols-2 gap-6 p-4">
  <div class="bg-gray-100 rounded-lg shadow-md p-4">
    <h2 class="text-2xl font-bold mb-3 text-blue-600">Entity</h2>
    <pre class="language-java bg-white rounded-md">
      <code bind:this={codeElements.entity} class="block p-4 overflow-x-auto h-fit">{entityCode}</code>
    </pre>
  </div>

  <div class="bg-gray-100 rounded-lg shadow-md p-4">
    <h2 class="text-2xl font-bold mb-3 text-green-600">Repository</h2>
    <pre class="language-java bg-white rounded-md">
      <code bind:this={codeElements.repository} class="block p-4 overflow-x-auto h-fit">{repositoryCode}</code>
    </pre>
  </div>

  <div class="bg-gray-100 rounded-lg shadow-md p-4">
    <h2 class="text-2xl font-bold mb-3 text-purple-600">Service</h2>
    <pre class="language-java bg-white rounded-md">
      <code bind:this={codeElements.service} class="block p-4 overflow-x-auto h-fit">{serviceCode}</code>
    </pre>
  </div>

  <div class="bg-gray-100 rounded-lg shadow-md p-4">
    <h2 class="text-2xl font-bold mb-3 text-red-600">Controller</h2>
    <pre class="language-java bg-white rounded-md">
      <code bind:this={codeElements.controller} class="block p-4 overflow-x-auto h-fit">{controllerCode}</code>
    </pre>
  </div>
</div>

<style>
  pre code:focus {
    outline: none;
  }
  pre code {
    font-size: 1em;
  }
</style>