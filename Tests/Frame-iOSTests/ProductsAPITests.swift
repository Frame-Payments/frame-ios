//
//  Test.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/1/25.
//

import XCTest
@testable import Frame

final class ProductsAPITests: XCTestCase {
    let session = MockURLAsyncSession(data: nil, response: HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/products")!,
                                                                           statusCode: 200,
                                                                           httpVersion: nil,
                                                                           headerFields: nil), error: nil)
    let productResponse = FrameObjects.Product(id: "prod_1", name: "Fake Product",
                                               livemode: false, image: nil,
                                               productDescription: "new product", url: nil,
                                               shippable: true, active: true,
                                               defaultPrice: 100, metadata: nil,
                                               object: "product", created: 0, updated: 0)
    
    func testCreateProduct() async {
        FrameNetworking.shared.asyncURLSession = session
        let request = ProductRequests.CreateProductRequest(name: "Fake Product", description: "new product", defaultPrice: 100, purchaseType: .oneTime)
        let creation = try? await ProductsAPI.createProduct(request: request).0
        XCTAssertNil(creation)
        
        do {
            session.data = try JSONEncoder().encode(productResponse)
            let (creationTwo, _) = try await ProductsAPI.createProduct(request: request)
            XCTAssertNotNil(creationTwo)
            XCTAssertEqual(creationTwo?.defaultPrice, productResponse.defaultPrice)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testUpdateProduct() async {
        FrameNetworking.shared.asyncURLSession = session
        let request = ProductRequests.UpdateProductRequest(name: "Fake Product", description: "new product", defaultPrice: 120)
        let creation = try? await ProductsAPI.updateProduct(productId: "prod_1", request: request).0
        XCTAssertNil(creation)
        
        do {
            session.data = try JSONEncoder().encode(productResponse)
            let (creationTwo, _) = try await ProductsAPI.updateProduct(productId: "prod_1", request: request)
            XCTAssertNotNil(creationTwo)
            XCTAssertEqual(creationTwo?.id, productResponse.id)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetProducts() async {
        FrameNetworking.shared.asyncURLSession = session
        let productResponseOne = try? await ProductsAPI.getProducts(perPage: nil, page: nil).0
        XCTAssertNil(productResponseOne)
        
        let productResponseTwo = try? await ProductsAPI.getProducts(perPage: 10, page: 1).0
        XCTAssertNil(productResponseTwo)
        
        do {
            session.data = try JSONEncoder().encode(ProductResponses.ListProductsResponse(meta: nil, data: [productResponse]))
            let (products, _) = try await ProductsAPI.getProducts(perPage: 10, page: 1)
            XCTAssertNotNil(products)
            XCTAssertEqual(products?.data?[0].name, productResponse.name)
            XCTAssertEqual(products?.data?[0].productDescription, productResponse.productDescription)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testGetProduct() async {
        FrameNetworking.shared.asyncURLSession = session
        let productResponseOne = try? await ProductsAPI.getProduct(productId: "").0
        XCTAssertNil(productResponseOne)
        
        let productResponseTwo = try? await ProductsAPI.getProduct(productId: "prod_1").0
        XCTAssertNil(productResponseTwo)
        
        do {
            session.data = try JSONEncoder().encode(productResponse)
            let (productThree, _) = try await ProductsAPI.getProduct(productId: "prod_1")
            XCTAssertNotNil(productThree)
            XCTAssertEqual(productThree?.productDescription, productResponse.productDescription)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testSearchProducts() async {
        FrameNetworking.shared.asyncURLSession = session
        let productResponseOne = try? await ProductsAPI.searchProduct(name: nil, active: nil, shippable: nil).0
        XCTAssertNil(productResponseOne)
        
        let productResponseTwo = try? await ProductsAPI.searchProduct(name: "Fake Product", active: true, shippable: nil).0
        XCTAssertNil(productResponseTwo)
        
        do {
            session.data = try JSONEncoder().encode(ProductResponses.SearchProductResponse(meta: nil, products: [productResponse]))
            let (products, _) = try await ProductsAPI.searchProduct(name: "Fake Product", active: true, shippable: nil)
            XCTAssertNotNil(products)
            XCTAssertEqual(products?.products?[0].name, productResponse.name)
            XCTAssertEqual(products?.products?[0].productDescription, productResponse.productDescription)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testDeleteProduct() async {
        FrameNetworking.shared.asyncURLSession = session
        let productResponse = try? await ProductsAPI.deleteProduct(productId: "").0
        XCTAssertNil(productResponse)
        
        let productResponseTwo = try? await ProductsAPI.deleteProduct(productId: "prod_1").0
        XCTAssertNil(productResponseTwo)
        
        let deletionResponse = ProductResponses.DeleteProductResponse(id: "prod_1", object: "product", deleted: true)
        do {
            session.data = try JSONEncoder().encode(deletionResponse)
            let (response, _) = try await ProductsAPI.deleteProduct(productId: "prod_1")
            XCTAssertNotNil(response)
            XCTAssertEqual(response?.id, deletionResponse.id)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
}
