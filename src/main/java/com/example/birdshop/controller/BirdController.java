package com.example.birdshop.controller;

import com.example.birdshop.model.Bird;
import com.example.birdshop.repository.BirdRepository;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/birds")
public class BirdController {
    private final BirdRepository repository;

    public BirdController(BirdRepository repository) {
        this.repository = repository;
    }

    @GetMapping
    public List<Bird> getAllBirds() {
        return repository.findAll();
    }

    @PostMapping
    public Bird addBird(@RequestBody Bird bird) {
        return repository.save(bird);
    }
}
