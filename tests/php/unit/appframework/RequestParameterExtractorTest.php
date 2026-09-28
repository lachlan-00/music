<?php declare(strict_types=1);

/**
 * Nextcloud Music app
 *
 * This file is licensed under the Affero General Public License version 3 or
 * later. See the COPYING file.
 *
 * @author Lachlan de Waard <lachlan.00@gmail.com>
 * @copyright Lachlan de Waard 2026
 */

namespace OCA\Music\AppFramework\Utility;

use OCP\IRequest;

/**
 * Dummy target used only to obtain a \ReflectionMethod with a realistic parameter set
 * (mandatory scalar, optional scalar with a default, and an array parameter).
 */
class RequestParameterExtractorTestTarget {
	public function method(int $id, string $type = 'song', array $ids = []) : void {
	}
}

class RequestParameterExtractorTest extends \PHPUnit\Framework\TestCase {

	protected function setUp() : void {
		// getRepeatedParam() (used for the array-typed `ids` parameter of the fixture method) reads
		// this directly, regardless of which test is running.
		$_SERVER['QUERY_STRING'] = '';
	}

	private function reflectionFor(string $method) : \ReflectionMethod {
		return new \ReflectionMethod(RequestParameterExtractorTestTarget::class, $method);
	}

	/**
	 * @param array<string, mixed> $params values returned from IRequest::getParam(), keyed by argument name
	 */
	private function requestWithParams(array $params) : IRequest {
		$mock = $this->getMockBuilder(IRequest::class)->getMock();
		$mock->method('getParam')->willReturnCallback(
			fn (string $key, $default = null) => $params[$key] ?? $default
		);
		return $mock;
	}

	public function testPrimaryNameIsUsedWhenPresent() : void {
		$request = $this->requestWithParams(['id' => 5, 'filter' => 99]);
		$extractor = new RequestParameterExtractor($request, [], ['id' => ['filter']]);

		[$id, $type, $ids] = $extractor->getParametersForMethod($this->reflectionFor('method'));

		$this->assertSame(5, $id);
		$this->assertSame('song', $type);
		$this->assertSame([], $ids);
	}

	public function testAliasIsUsedWhenPrimaryNameMissing() : void {
		$request = $this->requestWithParams(['filter' => 5]);
		$extractor = new RequestParameterExtractor($request, [], ['id' => ['filter']]);

		[$id] = $extractor->getParametersForMethod($this->reflectionFor('method'));

		$this->assertSame(5, $id);
	}

	public function testLaterAliasIsTriedWhenEarlierOneIsAbsent() : void {
		// `object_type` (checked first) isn't sent; the extractor must move on to `legacy_type`
		// rather than stopping at the first configured alias.
		$request = $this->requestWithParams(['id' => 5, 'legacy_type' => 'album']);
		$extractor = new RequestParameterExtractor($request, [], ['type' => ['object_type', 'legacy_type']]);

		[, $type] = $extractor->getParametersForMethod($this->reflectionFor('method'));

		$this->assertSame('album', $type);
	}

	public function testDefaultValueIsUsedWhenNeitherPrimaryNorAliasIsPresent() : void {
		$request = $this->requestWithParams(['id' => 5]);
		$extractor = new RequestParameterExtractor($request, [], ['type' => ['object_type']]);

		[, $type] = $extractor->getParametersForMethod($this->reflectionFor('method'));

		$this->assertSame('song', $type);
	}

	public function testAliasesAreNotConsultedForArrayParameters() : void {
		// `ids` isn't sent under its own name nor via QUERY_STRING/php://input (both empty here),
		// so it must come back empty even though an alias with a value is configured for it.
		$request = $this->requestWithParams(['id' => 5, 'some_alias' => '1,2,3']);
		$extractor = new RequestParameterExtractor($request, [], ['ids' => ['some_alias']]);

		[, , $ids] = $extractor->getParametersForMethod($this->reflectionFor('method'));

		$this->assertSame([], $ids);
	}
}
