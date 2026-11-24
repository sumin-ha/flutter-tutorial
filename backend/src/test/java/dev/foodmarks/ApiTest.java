package dev.foodmarks;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import java.time.Instant;
import java.util.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.assertj.core.api.Assertions.*;

@SpringBootTest(properties = {"spring.datasource.url=jdbc:h2:mem:test;DB_CLOSE_DELAY=-1", "app.google-key="})
@AutoConfigureMockMvc
class ApiTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired BookmarkRepository repository;
    private Map<String, Object> input() {
        return new HashMap<>(Map.of("title", "학습 맛집", "snsUrl", "https://www.instagram.com/p/example/",
            "description", "방문할 메뉴", "tags", List.of("혼밥", "국밥"),
            "address", "서울특별시 중구 세종대로 110", "placeId", "demo-seoul-cityhall"));
    }
    @Test void crudAndValidation() throws Exception {
        var body = input();
        String response = mvc.perform(post("/api/bookmarks").contentType("application/json").content(json.writeValueAsString(body)))
            .andExpect(status().isCreated()).andExpect(jsonPath("$.latitude").value(37.5663)).andReturn().getResponse().getContentAsString();
        String id = json.readTree(response).path("id").asText();
        mvc.perform(get("/api/bookmarks")).andExpect(status().isOk()).andExpect(jsonPath("$[0].title").value("학습 맛집"));
        body.put("title", "수정된 맛집");
        mvc.perform(put("/api/bookmarks/" + id).contentType("application/json").content(json.writeValueAsString(body)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.title").value("수정된 맛집"));
        body.put("snsUrl", "javascript:alert(1)");
        mvc.perform(post("/api/bookmarks").contentType("application/json").content(json.writeValueAsString(body))).andExpect(status().isBadRequest());
        body.put("snsUrl", "https://instagram.com/"); body.put("placeId", "fake-id");
        mvc.perform(post("/api/bookmarks").contentType("application/json").content(json.writeValueAsString(body))).andExpect(status().isBadRequest());
        mvc.perform(delete("/api/bookmarks/" + id)).andExpect(status().isNoContent());
        mvc.perform(delete("/api/bookmarks/" + id)).andExpect(status().isNotFound());
    }
    @Test void geocodingAndCacheExpiry() throws Exception {
        mvc.perform(get("/api/status")).andExpect(jsonPath("$.geocodingMode").value("demo"));
        mvc.perform(get("/api/geocode").param("address", "서울")).andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(2));
        mvc.perform(get("/api/geocode").param("address", "unknown")).andExpect(jsonPath("$.length()").value(0));
        String result = mvc.perform(post("/api/bookmarks").contentType("application/json").content(json.writeValueAsString(input())))
            .andReturn().getResponse().getContentAsString();
        var id = UUID.fromString(json.readTree(result).path("id").asText());
        Bookmark b = repository.findById(id).orElseThrow(); b.coordinatesExpireAt = Instant.now().minusSeconds(10); repository.save(b);
        mvc.perform(get("/api/bookmarks")).andExpect(status().isOk());
        assertThat(repository.findById(id).orElseThrow().latitude).isNull();
        assertThat(repository.findById(id).orElseThrow().placeId).isEqualTo("demo-seoul-cityhall");
        mvc.perform(post("/api/bookmarks/" + id + "/location")).andExpect(status().isOk()).andExpect(jsonPath("$.latitude").value(37.5663));
        repository.deleteById(id);
    }
    @Test void optionalThumbnailSurvivesReloadAndCanBeCleared() throws Exception {
        var body = input();
        body.put("thumbnailUrl", "https://example.com/food.jpg");
        String result = mvc.perform(post("/api/bookmarks").contentType("application/json").content(json.writeValueAsString(body)))
            .andExpect(status().isCreated()).andExpect(jsonPath("$.thumbnailUrl").value("https://example.com/food.jpg"))
            .andReturn().getResponse().getContentAsString();
        String id = json.readTree(result).path("id").asText();
        assertThat(repository.findById(UUID.fromString(id)).orElseThrow().thumbnailUrl).isEqualTo("https://example.com/food.jpg");
        body.put("thumbnailUrl", "");
        mvc.perform(put("/api/bookmarks/" + id).contentType("application/json").content(json.writeValueAsString(body)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.thumbnailUrl").value(""));
        body.put("thumbnailUrl", "javascript:alert(1)");
        mvc.perform(post("/api/bookmarks").contentType("application/json").content(json.writeValueAsString(body)))
            .andExpect(status().isBadRequest());
        mvc.perform(delete("/api/bookmarks/" + id)).andExpect(status().isNoContent());
    }
}
